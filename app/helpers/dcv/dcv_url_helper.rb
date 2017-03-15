module Dcv::DcvUrlHelper
  
  def link_to_site_landing_page(document, opts={})
    #url = site_path(document['slug'])
    #document, label: thumbnail_img_tag, class: 'thumbnail'
    slug = document['slug_ssim']
    is_restricted = document['restriction_ssim'].present? && restriction_ssim['restriction_ssim'].include?('Onsite')
    
    if opts[:label].present?
      link_label = opts[:label]
    else
      title_field_name = document_show_link_field(document)
      link_label = document[title_field_name].present? ? document[title_field_name].first : document.id
    end
    url = (is_restricted ? restricted_site_path(slug) : site_path(slug))
    link_to link_label, url, {class: opts[:class]}
  end
  
end