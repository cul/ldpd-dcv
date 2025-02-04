# frozen_string_literal: true

module Iiif::Authz::V2::Bytestreams
  extend ActiveSupport::Concern

  def request_origin(default = '*')
    request.headers['Origin'] || params[:origin] || default
  end

  # a proxy resource that redirects to actual content when permitted
  # this should be used as the resource in IIIF painting annotations with access restrictions
  def resource
    cors_headers(allow_origin: request_origin, allow_credentials: request_origin(false))
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    if @document.nil?
      render status: :not_found, plain: "resource not found"
      return
    end

    remote_ip = DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
    probe_response = probe_service_response(
      authorization: nil, bytestream_id: params[:bytestream_id], document: @document, remote_ip: remote_ip
    ).to_h
    case(probe_response[:status])
    when 302
      redirect_to probe_response[:location]
    else
      render body: nil, status: probe_response[:status]
    end
  end

  def probe_service_response(bytestream_id:, document:, remote_ip:, authorization: nil)
    Iiif::Authz::V2::ProbeService::Response.new(
      document: document, bytestream_id: bytestream_id, ability_helper: self, route_helper: self,
      remote_ip: remote_ip, authorization: authorization)
  end

  # IIIF Authorization 2.0 Probe Service
  # https://iiif.io/api/auth/2.0/#probe-service-response
  def probe_options
    cors_headers(allow_origin: request_origin, allow_credentials: request_origin(false), allow_headers: ['Authorization'])
    response.headers["Cache-Control"] = "no-cache, no-store"
    render body: nil
  end

  def has_probeable_resource?(solr_doc)
    return false unless solr_doc.present?
    resource_doc = resources_for_document(solr_doc, false).detect {|x| x[:id].split('/')[-1] == params[:bytestream_id]}
    return true if resource_doc.present?  
    (solr_doc.fetch('dc_type_ssm',[]) & ['StillImage', 'Image']).present?
  end

  def probe
    cors_headers(allow_origin: request_origin, allow_credentials: request_origin(false))
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    unless has_probeable_resource?(@document)
      render status: :not_found, plain: "resource not found"
      return
    end

    remote_ip = DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
    authorization = request.headers['Authorization']
    probe_response = probe_service_response(
      authorization: authorization, bytestream_id: params[:bytestream_id], document: @document, remote_ip: remote_ip
    ).to_h
    # IIIF Auth2 requires probe responses to have HTTP status 200, regardless of effective status in the response
    render json: probe_response, status: 200
  end

  # IIIF Authorization 2.0 Access Service
  # https://iiif.io/api/auth/2.0/#access-service
  def access
    response.headers["Cache-Control"] = "no-cache, no-store"
    respond_to do |format|
      format.html { render action: 'access', layout: 'minimal' }
    end
  end

  # IIIF Authorization 2.0 Token Service
  # https://iiif.io/api/auth/2.0/#access-token-service
  def token
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    message = {
      "@context": "http://iiif.io/api/auth/2/context.json",
      "type": "AuthAccessToken2",
      "messageId" => params[:messageId]
    }
    status = 400
    if can?(Ability::ACCESS_ASSET, @document)
      expires_in = DCV_CONFIG.dig('media_streaming','wowza', 'token_lifetime').to_i
      remote_ip = DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
      message.merge!({
        "accessToken" => Iiif::Authz::V2::AccessTokenService.token(params[:catalog_id], remote_ip, Time.now.utc.to_i, DCV_CONFIG.dig('iiif','authz','shared_secret')),
        "expiresIn" => DCV_CONFIG.dig('media_streaming','wowza', 'token_lifetime').to_i
      })
      status = 200
    else
      message.merge!("type": "AuthAccessTokenError2")
      if current_user
        message.merge!({
          "profile" => 'invalidAspect',
          "error" => 'invalidCredentials',
          "heading" => "Forbidden",
          "note" => { "en" => ["This material may be available in the reading room."] } 
        })
        status = 403
      else
        message.merge!({
          "profile" => 'missingAspect',
          "error" => 'missingCredentials',
          "heading" => "Unauthorized",
          "note" => { "en" => ["This material may be available after logging in."] } 
        })
        status = 401
      end
    end
    if params[:format] == 'json'
      cors_headers(content_type: "application/json", allow_origin: request_origin, allow_credentials: request_origin(false))
      render json: message, status: status
    else
      cors_headers(content_type: "text/html", allow_origin: request_origin)
      render Iiif::Authz::AccessTokenResponseComponent.new(message: message, origin: request_origin), layout: false, content_type: "text/html"
    end
  end
end
