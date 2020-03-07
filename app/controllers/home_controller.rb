# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class HomeController < ApplicationController

  include Blacklight::Catalog
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::DateRangeSelectorBehavior
  include Dcv::Catalog::RandomItemBehavior
  include Dcv::Catalog::ModsDisplayBehavior
  include Cul::Omniauth::AuthorizingController
  include Cul::Omniauth::RemoteIpAbility

  before_filter :authorize_action, only:[:restricted]
  before_filter :store_unless_user
  before_filter :set_browse_lists

  layout 'dcv'

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
  end

  def authorize_action
    authorized = (SUBSITES['restricted'].keys - ['uri']).detect do |key|
      c = "Restricted::#{(key + '_controller').camelcase}".constantize
      can?(Ability::ACCESS_SUBSITE, c)
    end

    if authorized
      return true
    else
      if current_user
        access_denied(catalog_index_url)
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  def search_action_url options = {}
    url_for(options.merge(:action => 'index', :controller=>'catalog'))
  end

  def index
  end
  
  def restricted
  end
  
  private
  
  def set_browse_lists
    @browse_lists = get_catalog_browse_lists
  end
  
end
