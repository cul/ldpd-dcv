class Restricted::UniversityseminarsController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::UniversityseminarsBlacklightConfigurator.configure(config)
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
