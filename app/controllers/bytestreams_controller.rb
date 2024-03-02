# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'actionpack/action_caching'
require 'digest'
require 'base64'

class BytestreamsController < ApplicationController
  include ActionController::Live
  include Dcv::CrossOriginRequests
  include Dcv::NonCatalog
  include Dcv::Resources::RelsIntBehavior
  include Dcv::Resources::LegacyIdBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::CatalogHelperBehavior
  include ChildrenHelper
  include Iiif::Authz::V2::Bytestreams
  #caches_action :content, :expires_in => 7.days

  before_action :require_user, only: [:access]

  respond_to :json

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 12
    }
    config[:unique_key] = :id
    config.index.title_field = 'title_display_ssm'
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
    cors_headers
    @response, @document = fetch(params[:catalog_id])
    resource_doc = resources_for_document.detect {|x| x[:id].split('/')[-1] == params[:id]} || {}
    render json: resource_doc, layout: false
  end

  def content_options
    @response, @document = fetch(params[:catalog_id])
    resource_doc = resources_for_document(@document, false).detect {|x| x[:id].split('/')[-1] == params[:bytestream_id]}
    deny_download = resource_doc.nil?
    if @document.nil? || deny_download
      render status: :not_found, plain: "resource not found"
      return
    end

    unless can?(Ability::ACCESS_ASSET, @document)
      render status: (current_user ? :forbidden : :unauthorized), plain: (current_user ? 'forbidden' : 'unauthorized')
      return
    end

    headers = {}
    headers["Allow"] = "OPTIONS, GET, HEAD"
    headers['Accept-Ranges'] = 'bytes' # Inform client that we accept range requests

    options 204, headers
  end

  def content_head
    @response, @document = fetch(params[:catalog_id])
    resource_doc = resources_for_document(@document, false).detect {|x| x[:id].split('/')[-1] == params[:bytestream_id]}
    deny_download = resource_doc.nil?
    if @document.nil? || deny_download
      render status: :not_found, plain: "resource not found"
      return
    end

    unless can?(Ability::ACCESS_ASSET, @document)
      render status: (current_user ? :forbidden : :unauthorized), plain: (current_user ? 'forbidden' : 'unauthorized')
      return
    end

    headers = {}
    headers["Last-Modified"] = @document['system_modified_dtsi'].present? ?
      DateTime.parse(@document['system_modified_dtsi']).httpdate : Time.now.httpdate

    ds_parms = {pid: params[:catalog_id], dsid: params[:bytestream_id]}

    # Get connection to Fedora
    repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)

    # Get size, label and mimetype for this datastream
    content_disposition = datastream_content_disposition(ds)
    headers["Content-Disposition"] = content_disposition if content_disposition
    headers[:content_type] = datastream_content_type(ds)

    headers['Accept-Ranges'] = 'bytes' # Inform client that we accept range requests
    headers['Content-Length'] = datastream_content_length(ds, repo, ds_parms)
    head 200, headers
  end

  def content
    @response, @document = fetch(params[:catalog_id])
    resource_doc = resources_for_document(@document, false).detect {|x| x[:id].split('/')[-1] == params[:bytestream_id]}
    deny_download = resource_doc.nil?
    if @document.nil? || deny_download
      render status: :not_found, plain: "resource not found"
      return
    end

    unless can?(Ability::ACCESS_ASSET, @document)
      render status: (current_user ? :forbidden : :unauthorized), plain: (current_user ? 'forbidden' : 'unauthorized')
      return
    end

    response.headers["ETag"] = Time.now.httpdate
    response.headers["Last-Modified"] = @document['system_modified_dtsi'].present? ?
      DateTime.parse(@document['system_modified_dtsi']).httpdate : response.headers["ETag"]

    ds_parms = {pid: params[:catalog_id], dsid: params[:bytestream_id]}

    # Get connection to Fedora
    repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)

    # Get size, label and mimetype for this datastream
    size = datastream_content_length(ds, repo, ds_parms)
    content_disposition = datastream_content_disposition(ds)
    response.headers["Content-Disposition"] = content_disposition if content_disposition
    response.headers["Content-Type"] = datastream_content_type(ds)

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

  def datastream_content_length(ds, repo, ds_parms)
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
    size
  end

  def datastream_content_disposition(ds)
    label = ds.dsLabel.present? ? ds.dsLabel.split('/').last : 'file'
    label_to_content_disposition(label,(params['download'].to_s == 'true')) if label
  end

  # translate a label into a rfc5987 encoded header value
  # see also http://tools.ietf.org/html/rfc5987#section-4.1
  def label_to_content_disposition(label,attachment=false)
    value = attachment ? 'attachment; ' : 'inline'
    value << "; filename*=utf-8''#{label.gsub(' ','%20').gsub(',','%2C')}"
    value
  end

  def datastream_content_type(ds)
    ds&.mimeType
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
