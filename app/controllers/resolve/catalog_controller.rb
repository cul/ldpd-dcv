# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class Resolve::CatalogController < ApplicationController
  include Dcv::NonCatalog
  include Dcv::Sites::LookupController
  include Dcv::Sites::SearchableController

  respond_to :json

  configure_blacklight do |config|
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
  end

  layout false

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def search_service
    Dcv::SearchService.new(config: blacklight_config, user_params: {})
  end

  def show
    @response, @document = fetch params[:id], q: "{!raw f=identifier_ssim v=$ids}"
    raise Blacklight::Exceptions::RecordNotFound.new unless @document.present?

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
end
