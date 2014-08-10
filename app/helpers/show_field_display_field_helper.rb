module ShowFieldDisplayFieldHelper

  def show_field_project_to_facet_link(args)
    facet_field_name = :lib_project_sim

    display_value = args[:document][args[:field]][0]

    full_project_names_to_short_project_names = I18n.t('ldpd.short.project').stringify_keys

    if full_project_names_to_short_project_names.has_key?(display_value)
      facet_value = full_project_names_to_short_project_names[display_value]
    else
      facet_value = display_value
    end

    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return link_to(display_value, url_for_facet_search)
  end

  def show_field_repository_to_facet_link(args)

    facet_field_name = :lib_repo_short_ssim

    long_repo_names_to_marc_codes = I18n.t('ldpd.full.repo').stringify_keys.invert
    marc_codes_to_short_repo_names = I18n.t('ldpd.short.repo').stringify_keys

    display_value = args[:document][args[:field]][0]
    facet_value = display_value # by default
    if long_repo_names_to_marc_codes.has_key?(display_value)
      repo_code = long_repo_names_to_marc_codes[display_value]
      if marc_codes_to_short_repo_names.has_key?(repo_code)
        facet_value = marc_codes_to_short_repo_names[repo_code]
      end
    end

    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return link_to(display_value, url_for_facet_search)
  end

  def link_to_url_value(args)
    url_value = args[:document][args[:field]][0]

    return link_to(url_value, url_value)
  end

end
