module Dcv::DigitalProjectsController
  extend ActiveSupport::Concern

  # requires Blacklight search action to have fetched site SolrDocuments
  def digital_projects
    #TODO: this should be handled outside the method
    unless @document_list
      (@response, @document_list) = search_results(params)
    end
    @document_list.delete_if{|doc| doc['source_ssim'].blank? && doc['slug_ssim'].blank? }.each.map do |solr_doc|
      t = {
        name: strip_restricted_title_qualifier(solr_doc.fetch('title_ssm',[]).first),
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.fetch('source_ssim',[]).first, # TODO: Handle landing page sites in this context
        description: solr_doc.fetch('abstract_ssim',[]).first,
        search_scope: solr_doc.fetch('search_scope_ssi', "project") || "project"
      }
      t[:facet_value] = solr_doc.fetch('short_title_ssim',[]).first if published_to_catalogs?(solr_doc)
      t[:facet_field] = (t[:search_scope] == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
      unless t[:external_url]
        t[:external_url] = solr_doc[:restriction_ssim].present? ? restricted_site_url(solr_doc.fetch('slug_ssim',[]).first) : site_url(solr_doc.fetch('slug_ssim',[]).first)
      end
      t
    end
  end

  def strip_restricted_title_qualifier(qualified_title)
    unqualified_title = qualified_title.dup
    unqualified_title.sub!(/\s*[\[\(]Restricted[\)\]]\s*/i, '')
    unqualified_title
  end

  def published_to_catalogs?(document={})
    document && (document.fetch('publisher_ssim',[]) & catalog_uris).present?
  end

  def catalog_uris
    ['restricted', 'public'].map { |top| SUBSITES[top].fetch('catalog',{})['uri'] }.compact
  end

end
