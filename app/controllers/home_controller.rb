# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class HomeController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Catalog::SearchParamsLogicBehavior
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
    @browse_lists = get_browse_lists
  end
  
end
