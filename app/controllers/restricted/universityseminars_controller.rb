class Restricted::UniversityseminarsController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::UniversityseminarsBlacklightConfigurator.configure(config)
    Dcv::Configurators::FullTextConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config)
  end

  def index
    super
    if !has_search_parameters? && request.format.html?
      # we override the view rendered for the subsite home on html requests
      render 'home'
    end
  end

  def thumb_url(document={})
    super
  end

end
