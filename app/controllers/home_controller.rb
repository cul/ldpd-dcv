# -*- encoding : utf-8 -*-

# This controller currently only answers requests for the /restricted "home" page
class HomeController < ApplicationController

  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Sites::ReadingRooms

  before_action :authorize_action, only:[:restricted]
  before_action :store_unless_user

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def subsite_config
    {'layout' => 'gallery', 'slug' => 'restricted'}
  end

  def subsite_styles
    ["#{subsite_layout}-#{Dcv::Sites::Constants.default_palette}", "catalog"]
  end

  def authorize_action
    return if current_ability.ip_to_location_uris(request.remote_ip).present?

    raise CanCan::AccessDenied unless current_user
  end
  
  def restricted
  end  
end
