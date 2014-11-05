class DurstController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
  end

  def index
    super
    render 'home' unless has_search_parameters?
  end

end
