# frozen_string_literal: true

module Iiif::Authz::V1::Bytestreams
  extend ActiveSupport::Concern

  # IIIF Authorization 1.0 Token Service
  # https://iiif.io/api/auth/2.0/#access-token-service
  def token
    @response, @document = fetch(params[:catalog_id])
    message = {}
    if can?(Ability::ACCESS_ASSET, @document)
      message.merge!({
        "accessToken" => Iiif::Authz::V2::AccessTokenService.token(params[:catalog_id]),
        "expiresIn" => DCV_CONFIG.dig('media_streaming','wowza', 'token_lifetime').to_i,
      })
    else
      if current_user
        message.merge!({
          "error" => 'invalidAspect',
          "description" => { "en" => ["You are not authorized to view this material, but it may be available in the reading room."] } 
        })
      else
        message.merge!({
          "error" => 'missingAspect',
          "description" => { "en" => ["This material may be available after logging in."] } 
        })
      end
    end 
    render Iiif::Authz::AccessTokenResponseComponent.new(message: message, origin: params[:origin]), layout: false
  end
end
