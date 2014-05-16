module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include Dcv::CatalogHelperBehavior


  def has_thumbnail? document
    true
  end

  def thumbnail_url(document, options={})
    controller.thumb_url(document.id)
  end

  def thumbnail_for_doc(document, image_options={})
    image_tag thumbnail_url(document), image_options
  end

  def short_link(document, opts={})
    title = document[document_show_link_field(document)]
    title = title.first if title.is_a? Array
    if title.length > 30
      title = title[0..26] + '...'
    end
    return link_to_document(document, {label: title}.merge(opts))
  end

end