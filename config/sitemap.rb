# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = Rails.application.config.default_host

SitemapGenerator::Sitemap.create_index = true

SitemapGenerator::Interpreter.send :include, Dcv::Sites::LookupController

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  all_sites = Site.all.includes(:scope_filters, :site_pages)
  all_sites.each do |site|
    next if site.slug == 'catalog'
    site_path = "/#{site.slug}"
    # sometimes there's junk in the site data for restricted slugs
    site_path = "/restricted#{site_path}".sub('/restricted/restricted', '/restricted') if site.restricted
    add site_path, lastmod: site.updated_at
    site.site_pages.each do |page|
      next if page.slug == 'home'
      add "#{site_path}/#{page.slug}", lastmod: site.updated_at
    end
  end

  # add links for custom side pages handled by dedicated actions
  # catalog/dlc
  add '/about'
  # carnegie from routes

  # durst from routes
  add '/durst/help'
  add '/durst/favorites'
  add '/durst/about_the_collection'
  add '/durst/about_the_project'
  add '/durst/acknowledgements'
  add '/durst/old_york_library_collection_categories'

  # ifp from routes
  %w(brazil chile china egypt ghana guatemala india indonesia kenya mexico mozambique nigeria palestine peru
     philippines russia senegal southafrica tanzania thailand uganda vietnam secretariat).each do |partner|
      add "/ifp/partner/#{partner}"
    end
  add '/ifp/about/about_the_ifp'
  add '/ifp/about/about_the_collection'

  # lcaaj from routes
  add '/lcaaj/about'

  # nyre from routes
  add '/nyre/about'
  add '/nyre/about-collection'

  # get DOI-keyed, best-site links to 
  addressible_search_types = [Site::SEARCH_CUSTOM, Site::SEARCH_LOCAL, Site::SEARCH_REPOSITORIES]
  site_candidates = all_sites.filter { |site| addressible_search_types.include? site.search_type }
  rows = 500
  total = 0
  blacklight_solr = Blacklight::Solr::Repository.new(Blacklight::Configuration.new)
  solr_params = {
    fq: ["active_fedora_model_ssi:(ContentAggregator or Collection)", "ezid_doi_ssim:*"],
    fl: '*',
    q: '*:*',
    rows: rows,
  }
  docs = []
  begin
    query = solr_params.merge(start: total)
    puts query.inspect
    response = blacklight_solr.search(query)
    puts response.header.inspect
    puts response.response.except(:docs).inspect
    docs = response&.documents || []
    total += docs.length
    docs.each do |solr_doc|
      matching_sites = site_matches_for(solr_doc, site_candidates)
      best_site = best_site_for(solr_doc, matching_sites)
      add doc_url_in_site_context(best_site, solr_doc), lastmod: solr_doc['system_modified_dtsi']
    end
  end while docs.present?
end
