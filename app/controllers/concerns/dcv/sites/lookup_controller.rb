module Dcv::Sites::LookupController
  SCOPE_FILTER_TYPE_SCORES = {
    'publisher' => 16,
    'project' => 8,
    'project_key' => 8,
    'collection' => 4,
    'collection_key' => 4,
    'repository_code' => 2
  }.freeze

  def doc_url_in_site_context(site, solr_doc)
    if site&.search_type == Site::SEARCH_CUSTOM
      helper = site.restricted ? "restricted_#{site.slug.sub(/^restricted\//,'')}_show_url" : "#{site.slug}_show_url"
      helper.gsub!('/', '_')
      send helper.to_sym, solr_doc
    elsif site&.search_type == Site::SEARCH_LOCAL
      url_for(controller: 'sites/search', site_slug: site.slug, id: solr_doc.doi_identifier, action: :show)
    else
      catalog_show_doi_url(solr_doc.doi_identifier)
    end
  end

  # filter db result for possible sites for those that the doc matches all criteria for
  def site_matches_for(solr_doc, site_candidates)
    site_candidates.select { |site| site.include? solr_doc }
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
    filter_clauses = scope_candidates.map do |scope_candidate|
      { "scope_filters.filter_type" => scope_candidate[0], "scope_filters.value" => scope_candidate[1] }
    end
    scope = Site.joins(:scope_filters).where(filter_clauses.shift)
    scope = filter_clauses.inject(scope) do |query, filter_clause|
      query.or(Site.joins(:scope_filters).where(filter_clause))
    end
    scope.includes(:scope_filters)
  end

  # Criteria:
  ## Custom Site (publisher) = 2^4 (unless catalog)
  ## project/project_key = 2^3
  ## collection/collection_key = 2^2
  ## repository_code = 2^1
  ## Custom site (catalog) = 2^0
  def match_score_for(site, solr_doc)
    return -1 unless site && solr_doc
    return 1 if site.slug == 'catalog'
    base_score = (site.include?(solr_doc) && !site.restricted) ? 1 : 0
    site.constraints.inject(base_score) do |score, entry|
      if (Array(solr_doc[ScopeFilter::FIELDS_FOR_FILTER_TYPES[entry[0]]]) & entry[1]).present?
        score + SCOPE_FILTER_TYPE_SCORES.fetch(entry[0], 0)
      else
        score
      end
    end
  end

  # score sites by strength of match
  # @return Site the best match for the document
  def best_site_for(solr_doc, sites)
    sites.inject([-1, nil]) do |best_tuple, next_site|
      next_score = match_score_for(next_site, solr_doc)
      if next_score == best_tuple[0]
        best_tuple[1] = next_site if (best_tuple[1].id > next_site.id)
      elsif next_score > best_tuple[0]
        best_tuple[0] = next_score
        best_tuple[1] = next_site
      end
      best_tuple
    end.second
  end
end
