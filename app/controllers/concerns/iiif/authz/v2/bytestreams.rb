# frozen_string_literal: true

module Iiif::Authz::V2::Bytestreams
  extend ActiveSupport::Concern

  # a proxy resource that redirects to actual content when permitted
  # this should be used as the resource in IIIF painting annotations with access restrictions
  def resource
    cors_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    if @document.nil?
      render status: :not_found, plain: "resource not found"
      return
    end

   remote_ip = DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
    probe_response = Iiif::Authz::V2::ProbeService::Response.new(document: @document, bytestream_id: params[:bytestream_id],ability_helper: self, route_helper: self, remote_ip: remote_ip).to_h
    case(probe_response[:status])
    when 302
      redirect_to probe_response[:location]
    else
      render json: probe_response
    end
  end

  # IIIF Authorization 2.0 Probe Service
  # https://iiif.io/api/auth/2.0/#probe-service-response
  def probe
    cors_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    resource_doc = resources_for_document(@document, false).detect {|x| x[:id].split('/')[-1] == params[:bytestream_id]}
    if @document.nil? || resource_doc.nil?
      render status: :not_found, plain: "resource not found"
      return
    end
    remote_ip = DCV_CONFIG.dig('media_streaming','wowza', 'client_ip_override') || request.remote_ip
    probe_response = Iiif::Authz::V2::ProbeService::Response.new(document: @document, bytestream_id: params[:bytestream_id], ability_helper: self, route_helper: self, remote_ip: remote_ip)
    render json: probe_response.to_h
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
    cors_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    @response, @document = fetch(params[:catalog_id])
    message = {
      "@context": "http://iiif.io/api/auth/2/context.json",
      "type": "AuthAccessToken2",
      "messageId" => params[:messageId]
    }
    status = 400
    if can?(Ability::ACCESS_ASSET, @document)
      message.merge!({
        "accessToken" => Iiif::Authz::V2::AccessTokenService.token(params[:catalog_id]),
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
      render json: message, status: status
    else
      render Iiif::Authz::AccessTokenResponseComponent.new(message: message, origin: params[:origin]), layout: false, content_type: "text/html"
    end
  end
end
