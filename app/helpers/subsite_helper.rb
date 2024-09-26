module SubsiteHelper
  def active_site_palette
    (@subsite&.layout == 'custom') ? 'custom' : controller.subsite_palette
  end

  def active_site_js
    (controller.subsite_layout == Site::LAYOUT_REPOSITORIES) ? 'gallery' : controller.subsite_layout
  end

  def map_search_settings_for_subsite
    if @subsite && @subsite.search_configuration.map_configuration.enabled
      map_config = @subsite.search_configuration.map_configuration
      # default_zoom and max_zoom must be translated from labeled values; show_items should be true if never set to a boolean value
      @map_search_settings_for_subsite ||= map_config.as_json.merge('default_zoom' => map_config.default_zoom, 'max_zoom' => map_config.max_zoom, 'show_items' => (map_config.show_items.nil? || map_config.show_items))
    else
      {}
    end
  end

  def signature_image_path
    @signature_image_path ||= controller.signature_image_path
  end

  def signature_banner_image_path
    @signature_banner_image_path ||= controller.signature_banner_image_path
  end

  def show_other_sources?
    controller.subsite_config.dig('display_options', 'show_other_sources') && @response.params[:q].present?
  end
end
