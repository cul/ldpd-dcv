class Restricted::UniversityseminarsController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::UniversityseminarsBlacklightConfigurator.configure(config)
    Dcv::Configurators::FullTextConfigurator.configure(config)
    # Include only this target's content in search results
    config.default_solr_params[:fq] << "publisher_ssim:\"#{subsite_config['uri']}\""
  end

  def index
	super
    unless has_search_parameters?
      render 'home'
    end
  end

  def thumb_url(document={})
    super
  end

end
