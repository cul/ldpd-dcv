module FieldDisplayHelpers::Project
  def show_field_project_to_facet_link(args)
    return args[:document][args[:field]] unless blacklight_config.show_fields[args[:field]].link_to_search
    facet_field_name = :lib_project_short_ssim
    full_project_names_to_short_project_names = get_full_project_names_to_short_project_names

    display_values = args[:document][args[:field]]
    display_values.map {|display_value|
      if full_project_names_to_short_project_names.has_key?(display_value)
        facet_value = full_project_names_to_short_project_names[display_value]
      else
        facet_value = display_value
      end

      url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
      return link_to(display_value, url_for_facet_search)
    }
  end

  def get_full_project_names_to_short_project_names
    full_project_names_to_original_project_names = HashWithIndifferentAccess.new(I18n.t('ldpd.full.project').invert)
    original_project_names_to_short_project_names = HashWithIndifferentAccess.new(I18n.t('ldpd.short.project'))

    new_hash = {}

    full_project_names_to_original_project_names.each {|key, value|
      new_hash[key] = original_project_names_to_short_project_names[value]
    }

    return new_hash
  end
end
