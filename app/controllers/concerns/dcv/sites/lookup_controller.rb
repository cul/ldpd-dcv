module Dcv::Sites::LookupController
  def doc_url_in_site_context(site, solr_doc)
    if site&.search_type == Site::SEARCH_CUSTOM
      helper = site.restricted ? "restricted_#{site.slug.sub(/^restricted\//,'')}_show_url".to_sym : "#{site.slug}_show_url".to_sym
      send helper, solr_doc
    elsif site&.search_type == Site::SEARCH_LOCAL
      url_for(controller: 'sites/search', site_slug: site.slug, id: solr_doc.doi_identifier, action: :show)
    else
      catalog_show_doi_url(solr_doc.doi_identifier)
    end
  end

  # filter db result for possible sites for those that the doc matches all criteria for
  def site_matches_for(solr_doc, site_candidates)
    site_candidates.select do |site|
      !site.default_filters.detect do |entry|
        (Array(solr_doc[entry[0]]) & entry[1]).blank?
      end
    end
  end

  # pull all solr values potentially used in a ScopeFilter
  # @return Hash map of filter types to values in solr_doc
  def scope_candidates_for(solr_doc)
    return {} if solr_doc.blank?
    ScopeFilter::FIELDS_FOR_FILTER_TYPES.inject({}) do |result, entry|
      filter_type, solr_field = entry
      if solr_doc[solr_field].present?
        result[filter_type] = Array(solr_doc[solr_field])
      end
      result
    end
  end

  def site_candidates_for(scope_candidates)
    return [] if scope_candidates.blank?
    where_clause = false
    scope = scope_candidates.inject do |query, scope_entry|
      query_values = [scope_entry[0]] + scope_entry[1]
      clauses = { "scope_filters.filter_type" => scope_entry[0], "scope_filters.value" => scope_entry[1] }
      where_clause ? query.or(Site.joins(:scope_filters).where(clauses)) : (where_clause ||= true) && Site.joins(:scope_filters).where(clauses)
    end
    scope.includes(:scope_filters)
  end
end
