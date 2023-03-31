class Dcv::Sites::SearchUrlService
  # this is only used from site home pages or the sites listing
  def search_controller_params(site, options = {})
    if site.search_type == 'custom'
      options.merge(controller: site.slug)
    elsif site.search_type == 'local'
      if site.restricted.present?
        slug_param = site.slug.sub("restricted/",'')
        options.merge(controller: '/restricted/sites/search', site_slug: slug_param)
      else
        options.merge(controller: '/sites/search', site_slug: site.slug)
      end
    else
      # delegate to relevant catalog
      # initialize with facet values if present
      if site.restricted.present?
        options.merge(controller: '/repositories/catalog', repository_id: site.repository_id)
      else
        options.merge(controller: '/catalog')
      end
    end
  end

  # build a search action URL per the site's configured search type
  def search_action_url(site, routing_context, options = {})
    case site.search_type
    when 'custom'
      # ignore the offered filters for full-fledged custom sites until either:
      # 1. there are multiple Solr cores
      # 2. there are collections published to non-catalog subsites
      url_params = search_controller_params(site, options.merge(action: 'index'))
    when 'local'
      url_params = search_controller_params(site, options.merge(action: 'index'))
    else
      # delegate to relevant catalog with pre-selected filters
      # initialize with facet values if present
      f = options.fetch('f', {}).merge(site.default_filters)
      url_params = search_controller_params(site, options.merge(action: 'index', f: f))
    end
    routing_context.url_for(url_params)
  end
end