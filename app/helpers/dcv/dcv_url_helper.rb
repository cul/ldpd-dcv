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

  def has_persistent_link?(document)
    document['ezid_doi_ssim'].present?
  end

  def preferred_content_bytestream(doc)
    doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
    if doc.is_a?(SolrDocument)
      datastreams = doc['datastreams_ssim'] || doc[:datastreams_ssim] || []
      return (['access','content'] & datastreams).first
    end
    return nil
  end

  def persistent_link_to(label, document, opts = {})
    link_to(label, persistent_url_for(document), opts)
  end

  def persistent_url_for(document)
    document['ezid_doi_ssim'][0].to_s.sub(/^doi\:/,'https://doi.org/')
  end

  def local_blank_search_url
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '' })
  end

  def local_image_search_url
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => (durst_format_list.keys.reject{|key| key == 'books'})}})
  end

  def local_book_search_url
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => ['books']}})
  end

  def local_facet_search_url(facet_field_name, value)
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {facet_field_name => [value]}})
  end

  def local_subject_search_url(subject_term_value)
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'durst_subjects_ssim' => [subject_term_value]}})
  end
end
