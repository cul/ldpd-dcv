module SubsiteHelper
  def map_search_settings_for_subsite
    if @subsite && @subsite.search_configuration.map_configuration.enabled
      map_config = @subsite.search_configuration.map_configuration
      @map_search_settings_for_subsite ||= map_config.as_json.merge('default_zoom' => map_config.default_zoom, 'max_zoom' => map_config.max_zoom)
    else
      {}
    end
  end

  def signature_image_path
    path = File.join("", "images", "sites", @subsite.slug, "signature.svg")
    File.exists?(File.join(Rails.root, "public", path)) ? path : asset_path("signature/signature.svg")
  end

  def signature_banner_image_path
    @signature_banner_image_path ||= begin
      path = File.join("", "images", "sites", @subsite.slug, "signature-banner.png")
      File.exists?(File.join(Rails.root, "public", path)) ? path : asset_path("signature/signature-banner.png")
    end
  end

  def show_other_sources?
    controller.subsite_config.dig('display_options', 'show_other_sources') && @response.params[:q].present?
  end
end
