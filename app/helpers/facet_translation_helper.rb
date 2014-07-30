module FacetTranslationHelper
  
  def show_field_project_to_facet_link(args)
    facet_field_name = :lib_project_sim
    
    display_value = args[:document][args[:field]][0]
    facet_value = I18n.t('ldpd.short.project.' + display_value, default: display_value)
    
    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return ('<a href="' + url_for_facet_search + '">' + display_value + '</a>').html_safe
  end
  
  def show_field_repository_to_facet_link(args)
    
    facet_field_name = :lib_repo_sim
    
    long_repo_names_to_marc_codes = I18n.t('ldpd.long.repo').invert
    marc_codes_to_short_repo_names = I18n.t('ldpd.short.repo')
    
    display_value = args[:document][args[:field]][0]
    facet_value = display_value # by default
    if long_repo_names_to_marc_codes.has_key?(display_value)
      repo_code = long_repo_names_to_marc_codes[display_value]
      if marc_codes_to_short_repo_names.has_key?(repo_code)
        facet_value = marc_codes_to_short_repo_names[repo_code]
      end
    end
    
    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return ('<a href="' + url_for_facet_search + '">' + display_value + '</a>').html_safe
  end
  
end
