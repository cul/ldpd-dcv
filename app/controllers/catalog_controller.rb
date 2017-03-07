class CatalogController < SubsitesController

  before_action :refresh_catalog_browse_lists_cache, only: [:home, :browse]

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

end
