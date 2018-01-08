module SubsiteHelper
  def map_search_settings_for_subsite
    if controller.respond_to? :subsite_config
      controller.subsite_config.fetch('map_search', {})
    else
      {}
    end
  end
end
