module ShowFieldDisplayFieldHelper

  def show_field_project_to_facet_link(args)
    facet_field_name = :lib_project_short_ssim

    display_value = args[:document][args[:field]][0]

    full_project_names_to_short_project_names = get_full_project_names_to_short_project_names

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

    full_repo_names_to_short_repo_names = get_full_repo_names_to_short_repo_names()

    display_value = args[:document][args[:field]][0]
    facet_value = display_value # by default
    if full_repo_names_to_short_repo_names.has_key?(display_value)
      facet_value = full_repo_names_to_short_repo_names[display_value]
    end

    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return link_to(display_value, url_for_facet_search)
  end

  def link_to_url_value(args)
    url_value = args[:document][args[:field]][0]

    return link_to(url_value, url_value)
  end

  def get_full_repo_names_to_short_repo_names
    full_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.full.repo').invert)
    marc_codes_to_short_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo'))

    new_hash = {}

    full_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_short_repo_names[value]
    }

    return new_hash
  end

  def get_long_repo_names_to_short_repo_names
    full_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.long.repo').invert)
    marc_codes_to_short_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo'))

    new_hash = {}

    full_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_short_repo_names[value]
    }

    return new_hash
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
