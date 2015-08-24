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
    if Rails.env == 'development' || ! Rails.cache.exist?(BROWSE_LISTS_KEY)
      refresh_browse_lists_cache
    end
    @browse_lists = Rails.cache.read(BROWSE_LISTS_KEY)

  end
  def restricted
    if Rails.env == 'development' || ! Rails.cache.exist?(BROWSE_LISTS_KEY)
      refresh_browse_lists_cache
    end
    @browse_lists = Rails.cache.read(BROWSE_LISTS_KEY)
  end
end
