class CatalogController < SubsitesController

  before_action :refresh_browse_lists_cache, only: [:home, :browse]

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
  end

end
