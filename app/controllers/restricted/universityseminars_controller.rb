class Restricted::UniversityseminarsController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::UniversityseminarsBlacklightConfigurator.configure(config)
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

  def subsite_layout
    'signature'
  end

  def subsite_palette
    'blue'
  end

  def carousel_image_paths
    @carousel_image_paths ||= [
      "universityseminars/home-ss/slide-0.jpg",
      "universityseminars/home-ss/slide-1.jpg",
      "universityseminars/home-ss/slide-2.jpg",
      "universityseminars/home-ss/slide-3.jpg",
      "universityseminars/home-ss/slide-4.jpg"
    ].map { |path| view_context.asset_path(path) }
  end
end
