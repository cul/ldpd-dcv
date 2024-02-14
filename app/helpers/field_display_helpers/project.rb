module FieldDisplayHelpers::Project
  def is_catalog_site?(*args)
    return true if controller.load_subsite&.slug == 'catalog'
  end

  def show_digital_project?(field_config, document)
    return false unless is_catalog_site?(field_config, document) && document[:other_sites_data].blank?
    return false if has_unless_field?(field_config, document)
    true
  end

  def show_field_project_to_facet_link(args)
    return args[:document][args[:field]] unless blacklight_config.show_fields[args[:field]].link_to_search
    projects_config = Rails.application.config_for(:hyacinth_projects)

    display_values = args[:document][args[:field]]
    display_values.map {|display_value|
      config_key = display_value.to_sym
      unless projects_config[config_key]
        config_key = projects_config.detect {|key, label_entries| label_entries.values.include?(display_value)}&.[](0)
      end
      if config_key && projects_config[config_key]
        url_for_facet_search = search_catalog_path(f: { project_key: [config_key] })
        link_to(projects_config.dig(config_key, :full), url_for_facet_search)
      else
        display_value
      end
    }
  end
end
