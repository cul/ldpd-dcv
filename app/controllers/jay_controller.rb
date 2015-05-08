class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::JayBlacklightConfigurator.configure(config)
  end

  def index
	super
    unless has_search_parameters?
      render 'home'
    end
  end

end
