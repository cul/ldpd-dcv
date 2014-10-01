class IfpController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::IfpBlacklightConfigurator.configure(config)
  end

  def index
    if has_search_parameters?
      super
    else
      render 'home'
    end
  end

end
