# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'actionpack/action_caching'

class BytestreamsController < ApplicationController
  include ActionController::Live
  include Dcv::NonCatalog
  include Dcv::Resources::RelsIntBehavior
  include Dcv::Resources::LegacyIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::CatalogHelperBehavior
  include ChildrenHelper
  #caches_action :content, :expires_in => 7.days

  respond_to :json

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 12
    }
    config[:unique_key] = :id
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
  end

  # overrides the session role key from Cul::Omniauth::RemoteIpAbility
  def current_ability
    @current_ability ||= Ability.new(current_user, roles: session["cul.roles"], remote_ip:request.remote_ip)
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    id.gsub!(/\:/,'\:')
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{id}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::RecordNotFound.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def index
  	@response, @document = fetch(params[:catalog_id])
    render json: resources_for_document, layout: false
  end

  def show
  	@response, @document = fetch(params[:catalog_id])
  	doc = resources_for_document.select {|x| x[:id].split('/')[-1] == params[:id]}
  	doc = doc.first || {}
    render json: doc, layout: false
  end

  def content
    @response, @document = fetch(params[:catalog_id])
    if @document.nil?
      render :status => 404
      return
    end

    unless can?(Ability::ACCESS_ASSET, @document)
      render status: (current_user ? :forbidden : :unauthorized), text: (current_user ? 'forbidden' : 'unauthorized')
      return
    end 

    response.headers["Last-Modified"] = (DateTime.parse(@document['system_modified_dtsi']) || Time.now).httpdate

    ds_parms = {pid: params[:catalog_id], dsid: params[:bytestream_id]}

    # Get connection to Fedora
    repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)

    # Get size, label and mimetype for this datastream
    size = params[:file_size] || params['file_size']
    size ||= ds.dsSize
    if size.blank? || size == 0
      # Get size of this datastream if we haven't already.  Note: dsSize property won't work for external datastreams
      # From: https://github.com/samvera/rubydora/blob/1e6980aa1ae605677a5ab43df991578695393d86/lib/rubydora/datastream.rb#L423-L428
      repo.datastream_dissemination(ds_parms.merge(method: :head)) do |resp|
        if content_length = resp['Content-Length']
          size = content_length.to_i
        else
          size = resp.body.length
        end
      end
    end
    label = ds.dsLabel.present? ? ds.dsLabel.split('/').last : 'file'
    if label
      response.headers["Content-Disposition"] = label_to_content_disposition(label,(params['download'].to_s == 'true'))
    end
    response.headers["Content-Type"] = ds.mimeType

    # Handle range requests
    response.headers['Accept-Ranges'] = 'bytes' # Inform client that we accept range requests
    length = size # no length specified by default
    content_headers_for_fedora = {}
    success = 200
    if request.headers['Range'].present?
      # Example Range header value: "bytes=18022400-37581888"
      range_matchdata = request.headers['Range'].match(/bytes=(\d+)-(\d+)*/)
      if range_matchdata
        from = range_matchdata.captures[0].to_i
        to = size - 1 # position for full size assumed by default
        if range_matchdata.captures.length > 1 && range_matchdata.captures[1].present?
          to = range_matchdata.captures[1].to_i
        end
        length = (to - from) + 1 # Adding 1 because to and from are zero-indexed
        success = 206
        content_headers_for_fedora = {'Range' => "bytes=#{from}-#{to}"}
        response.headers["Content-Range"] = "bytes #{from}-#{to}/#{size}"
        response.headers["Cache-Control"] = 'no-cache'
      end
    end

    response.headers["Content-Length"] = length.to_s

    # Rails 4 Streaming method
    repo.datastream_dissemination(ds_parms.merge(:headers => content_headers_for_fedora)) do |resp|
      response.status = success
      begin
        resp.read_body do |seg|
          response.stream.write seg
        end
      ensure
        response.stream.close
      end
    end
  end

  # translate a label into a rfc5987 encoded header value
  # see also http://tools.ietf.org/html/rfc5987#section-4.1
  def label_to_content_disposition(label,attachment=false)
    value = attachment ? 'attachment; ' : 'inline'
    value << "; filename*=utf-8''#{label.gsub(' ','%20').gsub(',','%2C')}"
    value
  end

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def search_service
    Blacklight::SearchService.new(config: blacklight_config, user_params: {})
  end

  def fetch(id = nil, extra_controller_params = {})
    return search_service.fetch(id, extra_controller_params) unless extra_controller_params[:q]
    extra_controller_params[:q] = extra_controller_params[:q].sub('$ids', '$id')
    extra_controller_params[:q] << id
    id = [] # avoids fetch_one for more backwards-compatible fetch_many
    solr_response = search_service.fetch(id, extra_controller_params).first
    [solr_response, solr_response.documents.first]
  end
end
