# -*- encoding : utf-8 -*-

# This controller currently only answers requests for the /restricted "home" page
class Iiif::AccessController < ApplicationController

  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::CrossOriginRequests

  before_action :authorize_action, only: [:kiosk]
  before_action :require_user, only: [:login]

  def authorize_action
    return if current_ability.ip_to_location_uris(request.remote_ip).present?

    raise CanCan::AccessDenied unless current_user
  end

  def kiosk
  end

  def login
    cors_headers(content_type: 'text/html', allow_origin: request_origin, allow_credentials: request_origin(false))
    respond_to do |format|
      format.html { render action: 'login', layout: 'minimal' }
    end
  end
end
