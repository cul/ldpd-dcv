# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class Resolve::DoisController < ApplicationController

  include Dcv::NonCatalog

  SCOPE_FILTER_TYPE_SCORES = {
    'publisher' => 16,
    'project' => 8,
    'project_key' => 8,
    'collection' => 4,
    'collection_key' => 4,
    'repository_code' => 2
  }.freeze

  respond_to :json

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
  end

  layout false

  def resolve
    doi = "#{params[:registrant]}/#{params[:doi]}"
    @response, @document = fetch "doi:#{doi}", q: "{!raw f=ezid_doi_ssim v=$id}"
    search_session.delete('counter') # do not set up search prev/next on resolved doc
    best_site = best_site_for(@document, site_matches_for(@document, site_candidates_for(scope_candidates_for(@document))))
    redirect_to resolve_doc_for(best_site, @document)
  end

  def resolve_doc_for(site, solr_doc)
    if site&.search_type == Site::SEARCH_CUSTOM
      helper = site.restricted ? "restricted_#{site.slug}_show_url".to_sym : "#{site.slug}_show_url".to_sym
      send helper, solr_doc
    elsif site&.search_type == Site::SEARCH_LOCAL
      url_for(controller: 'sites/search', site_slug: site.slug, id: solr_doc.doi_identifier, action: :show)
    else
      catalog_show_doi_url(solr_doc.doi_identifier)
    end
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
    site.constraints.inject(0) do |score, entry|
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
    sites = 
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
    all_values = []
    clauses = scope_candidates.map do |filter_type, values|
      (all_values << filter_type).concat(values)
      values_sub = values.map {|x| '?'}.join(',')
      "(scope_filters.filter_type = ? AND scope_filters.value IN (#{values_sub}))"
    end
    Site.joins(:scope_filters).where(clauses.join(" OR "), *all_values).includes(:scope_filters)
  end
end
