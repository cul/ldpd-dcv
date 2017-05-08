module Dcv::DcvUrlHelper
  # TODO: delete this method
  def link_to_site_landing_page(document, opts={})
    #url = site_path(document['slug'])
    #document, label: thumbnail_img_tag, class: 'thumbnail'
    slug = document['slug_ssim']
    is_restricted = document['restriction_ssim'].present? && doc['restriction_ssim'].include?('Onsite')
    
    if opts[:label].present?
      link_label = opts[:label]
    else
      title_field_name = document_show_link_field(document)
      link_label = document[title_field_name].present? ? document[title_field_name].first : document.id
    end
    url = (is_restricted ? restricted_site_path(slug) : site_path(slug))
    link_to link_label, url, {class: opts[:class]}
  end

  def url_for_document(doc, options = {})
    doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
    if doc.is_a?(SolrDocument) && doc.site_result?
      slug = doc['slug_ssim']
      is_restricted = doc['restriction_ssim'].present? && doc['restriction_ssim'].include?('Onsite')
      is_restricted ? restricted_site_path(slug) : site_path(slug)
    else
      super
    end
  end
end