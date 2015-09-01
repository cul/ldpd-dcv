module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include Dcv::CatalogHelperBehavior
  include Cul::Hydra::OreProxiesHelperBehavior
  include Cul::Hydra::StructMetadataHelperBehavior
  include Dcv::Resources::RelsIntBehavior

  def has_thumbnail? document
    true
  end

  def thumbnail_url(document, options={})
    get_asset_url(id: document.id, size: 256, type: 'square', format: 'jpg')
  end

  def thumbnail_for_doc(document, image_options={})
    image_tag thumbnail_url(document), image_options
  end

  def thumbnail_placeholder(document, image_options={})
    image_tag image_url('file-placeholder.png')
  end

  def short_link(document, opts={})
    title = document[document_show_link_field(document)]
    title = title.first if title.is_a? Array
    if title.length > 30
      title = title[0..26] + '...'
    end
    return link_to_document(document, {label: title}.merge(opts))
  end

  def resources_as_list_items(document=@document, css_class)
    list_items = resources_for_document(document).collect do |doc|
      p = doc[:id].split('/')
      id = p[-1]
      c_id = p[-2]
      title = doc[:title]
      ext = doc[:mime_type].split('/')[-1].downcase
      "<li><a href=\"#{doc[:url]}\" target=\"_blank\">#{title}.#{ext} (#{doc[:width]}x#{doc[:length]})</a></li>".html_safe
    end
    list_items
  end
end