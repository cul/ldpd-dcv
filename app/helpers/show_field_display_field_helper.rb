module ShowFieldDisplayFieldHelper

  def show_field_project_to_facet_link(args)
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

  def show_field_repository_to_facet_link(args)

    facet_field_name = :lib_repo_short_ssim
    full_repo_names_to_short_repo_names = get_full_repo_names_to_short_repo_names()

    display_values = args[:document][args[:field]]

    display_values.map {|display_value|
      facet_value = display_value # by default
      if full_repo_names_to_short_repo_names.has_key?(display_value)
        facet_value = full_repo_names_to_short_repo_names[display_value]
      end

      url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})

      if display_value == 'Non-Columbia Location' && args[:document].get('lib_repo_text_ssm').present?
        return (args[:document].get('lib_repo_text_ssm') + '<br />' + link_to("(#{display_value})", url_for_facet_search)).html_safe
      else
        src = [link_to_repo_homepage(facet_value)]
        src << '<em>' + 
              link_to("Browse Location’s Digital Content",
                      url_for_facet_search) + '</em>'
        src.compact.join('<br />').html_safe
      end
    }
  end

  def link_to_url_value(args)
    values = args[:document][args[:field]]

    values.map {|value|
      link_to(value, value)
    }
  end

  def dirname_prefixed_with_slash(args)
    values = args[:document][args[:field]]

    values.map {|value|
      value = '/' + value unless value.start_with?('/')

      dirname = File.dirname(value)
      dirname = '/' if dirname == '.'

      return dirname
    }
  end




  def get_short_repo_names_to_full_repo_names
    short_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo').invert)
    marc_codes_to_full_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.full.repo'))

    new_hash = {}

    short_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_full_repo_names[value]
    }

    return new_hash
  end

  def get_short_repo_names_to_urls
    short_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo').invert)
    marc_codes_to_urls = HashWithIndifferentAccess.new(I18n.t('ldpd.url.repo'))

    new_hash = {}

    short_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_urls[value]
    }

    return new_hash
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

  # Link to a translated lib_repo_short_ssim value
  # as a library location URL, if available
  def link_to_repo_homepage(repo_short)
    url = get_short_repo_names_to_urls[repo_short]
    return unless url
    label = get_short_repo_names_to_full_repo_names.fetch(repo_short, repo_short)
    link_to(label, url)
  end
end
