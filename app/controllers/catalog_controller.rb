class CatalogController < SubsitesController

  before_action :refresh_browse_lists_cache, only: [:home, :browse]

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include only this target's content in search results
    config.default_solr_params[:fq] << "publisher_ssim:\"#{subsite_config['uri']}\""
  end

end
