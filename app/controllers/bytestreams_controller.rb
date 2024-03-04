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

    # Get size, label and mimetype for this datastream
    content_disposition = document_content_disposition
    headers["Content-Disposition"] = content_disposition if content_disposition
    headers[:content_type] = document_content_type || datastream_content_type(ds_parms)

    headers['Accept-Ranges'] = 'bytes' # Inform client that we accept range requests
    headers['Content-Length'] = datastream_content_length(ds_parms)
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

    content_disposition = document_content_disposition
    response.headers["Content-Disposition"] = content_disposition if content_disposition
    response.headers["Content-Type"] = document_content_type || datastream_content_type(ds_parms)
    response.headers['Accept-Ranges'] = 'bytes' # Inform client that we accept range requests
    response.headers['X-Accel-Buffering'] = 'off'
    if params['download'].to_s == 'true'
      response.headers['X-Accel-Redirect'] = x_accel_url(ds_content_url(params[:catalog_id], params[:bytestream_id]), document_bytestream_filename)
    else
      response.headers['X-Accel-Redirect'] = x_accel_url(ds_content_url(params[:catalog_id], params[:bytestream_id]))
    end
    response.headers['X-Range'] = request.headers['Range'] if request.headers['Range'].present?
    render body: nil
  end

  def object_profile
    return unless @document
    @object_profile ||= begin
      object_profile_src = Array(@document[:object_profile_ssm]).join
      JSON.load(object_profile_src) unless object_profile_src.blank?
    end
  end

  def datastream_content_length(ds_parms)
    size = params[:file_size] || params['file_size']
    size ||= object_profile&.dig('datastreams', params[:bytestream_id], 'dsSize')
    if size.blank? || size == 0
      doc_size = Array(@document&.fetch(:extent_ssim, nil)).first if params[:bytestream_id] == 'content'
      return doc_size.to_i if /^\d+/ === doc_size

      # Get connection to Fedora
      repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
      ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)

      # Get size of this datastream if we haven't already.  Note: dsSize property won't work for external datastreams
      # From: https://github.com/samvera/rubydora/blob/1e6980aa1ae605677a5ab43df991578695393d86/lib/rubydora/datastream.rb#L423-L428
      repo.datastream_dissemination(ds_parms.merge(method: :head)) do |resp|
        if content_length = resp['Content-Length']
          size = content_length.to_i
        end
      end
    end
    size
  end

  def document_bytestream_filename
    dsLabel = object_profile&.dig('datastreams', params[:bytestream_id], 'dsLabel')
    dsLabel.present? ? dsLabel.split('/').last : 'file'
  end

  def document_content_disposition
    label = document_bytestream_filename
    label_to_content_disposition(label,(params['download'].to_s == 'true')) if label
  end

  def ds_content_url(fedora_pid, dsid)
    Rails.application.config_for(:fedora)[:url] + '/objects/' + fedora_pid + '/datastreams/' + dsid + '/content'
  end

  # Downloading of files is handed off to nginx to improve performance.
  # Uses the x-accel-redirect header in combination with nginx config location
  # syntax `repository_download` to have nginx proxy the download.
  # See https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/
  # See http://kovyrin.net/2010/07/24/nginx-fu-x-accel-redirect-remote/
  def x_accel_url(url, filename = nil)
    uri = "/repository_download/#{url.gsub(/https?\:\/\//, '')}"
    return uri unless filename
    uri << "?#{filename}"
  end

  # translate a label into a rfc5987 encoded header value
  # see also http://tools.ietf.org/html/rfc5987#section-4.1
  def label_to_content_disposition(label,attachment=false)
    value = attachment ? 'attachment' : 'inline'
    value << "; filename*=utf-8''#{label.gsub(' ','%20').gsub(',','%2C')}"
    value
  end

  def datastream_content_type(ds_parms)
    ds = Cul::Hydra::Fedora.ds_for_opts(ds_parms)
    ds&.mimeType
  end

  def document_content_type
    object_profile&.dig('datastreams', params[:bytestream_id], 'dsMIME')
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
