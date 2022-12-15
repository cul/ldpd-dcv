# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class Resolve::DoisController < ApplicationController
  include Dcv::NonCatalog
  include Dcv::Sites::LookupController
  include Dcv::Sites::SearchableController

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

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def search_service
    Dcv::SearchService.new(config: blacklight_config, user_params: {})
  end

  def resolve
    doi = "#{params[:registrant]}/#{params[:doi]}"
    @response, @document = fetch "doi:#{doi}", q: "{!raw f=ezid_doi_ssim v=$ids}"
    search_session.delete('counter') # do not set up search prev/next on resolved doc
    if @document.site_result?
      href_params = { controller: '/sites', slug: @document.unqualified_slug, action: 'home' }
      href_params[:controller] = '/restricted/sites' if @document.has_restriction?
      redirect_to url_for(href_params)
    else
      best_site = best_site_for(@document, site_matches_for(@document, site_candidates_for(scope_candidates_for(@document))))
      redirect_to doc_url_in_site_context(best_site, @document)
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
