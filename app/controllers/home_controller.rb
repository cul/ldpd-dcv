# -*- encoding : utf-8 -*-

# This controller currently only answers requests for the /restricted "home" page
class HomeController < ApplicationController

  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::Sites::ConfiguredLayouts

  before_action :authorize_action, only:[:restricted]
  before_action :store_unless_user

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def subsite_config
    {'layout' => 'gallery', 'slug' => 'restricted'}
  end

  def authorize_action
    return true if current_ability.ip_to_location_uris(request.remote_ip).present?

    if current_user
      return true
    else
      store_location
      redirect_to_login
      return false
    end
  end
  
  def restricted
  end  
end
