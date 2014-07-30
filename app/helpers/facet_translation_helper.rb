module FacetTranslationHelper
  
  def show_field_project_to_facet_link(args)
    facet_field_name = :lib_project_sim
    
    display_value = args[:document][args[:field]][0]
    facet_value = I18n.t('ldpd.short.project.' + display_value, default: display_value)
    
    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return ('<a href="' + url_for_facet_search + '">' + display_value + '</a>').html_safe
  end
  
  def show_field_repository_to_facet_link(args)
    
    # We're not currently storing MARC repo codes, so we can't use our translation file to translate these
    # This is a temporary fix
    long_repo_names_to_short_repo_names = {
      'Barnard College Library' => 'Barnard College Library',
      'Columbia University Libraries' => 'Butler Library',
      'Avery Architectural & Fine Arts Library, Columbia University' => 'Avery Library',
      'Office of Art Properties' => 'Office of Art Properties',
      'C.V. Starr East Asian Library, Columbia University' => 'East Asian Library',
      'Arthur W. Diamond Law Library, Columbia University' => 'Law Library',
      'Augustus C. Long Health Sciences Library, Columbia University' => 'Health Sciences Library',
      'Music Library' => 'Music Library',
      'Rare Book & Manuscript Library, Columbia University' => 'Rare Book Library',
      'University Archives, Columbia University' => 'University Archives',
      'Burke Library at Union Theological Seminary, Columbia University' => 'Burke Library',
      'Columbia Center for Oral History, Columbia University' => 'Oral History',
      'Art Properties, Columbia University' => 'Art Properties',
      'Gabe M. Wiener Music & Arts Library, Columbia University' => 'Music Library',
      'Royal Archives, Windsor Castle' => 'Royal Archives, Windsor Castle',
    }
    
    facet_field_name = :lib_repo_sim
    
    display_value = args[:document][args[:field]][0]
    facet_value = (long_repo_names_to_short_repo_names.has_key?(display_value) ? long_repo_names_to_short_repo_names[display_value] : display_value)
    
    url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})
    return ('<a href="' + url_for_facet_search + '">' + display_value + '</a>').html_safe
  end
  
end
