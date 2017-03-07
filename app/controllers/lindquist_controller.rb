class LindquistController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    if has_search_parameters?
      super
    else
      render 'home'
    end
  end

end
