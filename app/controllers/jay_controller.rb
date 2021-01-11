class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::JayBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def index
    super
    if !has_search_parameters? && request.format.html?
      # we override the view rendered for the subsite home on html requests
      params[:action] = 'home'
      render 'home'
    end
  end
end
