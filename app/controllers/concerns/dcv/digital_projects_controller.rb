module Dcv::DigitalProjectsController
  extend ActiveSupport::Concern

  # requires Blacklight search action to have fetched site SolrDocuments
  def digital_projects
    #TODO: this should be handled outside the method
    unless @document_list
      (@response, @document_list) = search_results(params)
    end
    custom_slugs = Site.where(search_type: "custom").pluck(:slug)
    @document_list.delete_if{|doc| doc['source_ssim'].blank? && doc['slug_ssim'].blank? }.each.map do |solr_doc|
      t = {
        id: solr_doc['id'],
        name: strip_restricted_title_qualifier(solr_doc.fetch('title_ssm',[]).first),
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.has_persistent_url? ? solr_doc.persistent_url : nil,
        description: solr_doc.fetch('abstract_ssim',[]).first,
        search_scope: solr_doc.fetch('search_scope_ssi', "project") || "project"
      }
      url_params = { slug: solr_doc.unqualified_slug, action: 'home' }
      if solr_doc[:restriction_ssim].present?
        url_params[:controller] = 'restricted/sites'
      else
        url_params[:controller] = 'sites'
      end
      unless t[:external_url]
        t[:external_url] = url_for(url_params)
      end
      if published_to_catalogs?(solr_doc)
        slug = solr_doc.unqualified_slug
        if custom_slugs.include? slug
          url_params = { controller: "/#{slug}", action: 'index', q: '', search_field: 'all_text_teim' }
        else
          search_controller = url_params[:controller] + "/search"
          url_params = { controller: search_controller, site_slug: solr_doc.unqualified_slug, action: 'index', q: '', search_field: 'all_text_teim' }
        end
        t[:browse_url] = url_for(url_params)
      end
      t
    end
  end

  def strip_restricted_title_qualifier(qualified_title)
    unqualified_title = qualified_title.dup
    unqualified_title&.sub!(/\s*[\[\(]Restricted[\)\]]\s*/i, '')
    unqualified_title
  end

  def published_to_catalogs?(document={})
    document && (document.fetch('publisher_ssim',[]) & catalog_uris).present?
  end

  def catalog_uris
    ['restricted', 'public'].map { |top| SUBSITES[top].fetch('catalog',{})['uri'] }.compact
  end

end
