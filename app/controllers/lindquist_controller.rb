class LindquistController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def index
    if has_search_parameters?
      super
    else
      render 'home'
    end
  end

end
