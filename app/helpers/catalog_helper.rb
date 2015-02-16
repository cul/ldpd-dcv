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
  #TODO migrate this URI escapig logic below into the engine
  def proxies(opts=params, &block)
    proxy_in = opts[:id]
    proxy_uri = "info:fedora/#{proxy_in}"
    proxy_id = opts[:proxy_id]
    proxy_in_query = "proxyIn_ssi:#{RSolr.escape(proxy_uri)}"
    f = [proxy_in_query]
    if proxy_id
      pr_parts = proxy_id.split('/')
      pr_parts.collect! do |p|
        if( p.eql? proxy_in) || (p.eql? 'info:fedora')
          p
        else
          URI.encode(p)
        end
      end
      proxy_id = pr_parts.join('/')
      f << "belongsToContainer_ssi:#{RSolr.escape(proxy_id)}"
    else
      f << "-belongsToContainer_ssi:*"
    end
    rows = opts[:limit] || '999'
    proxies = ActiveFedora::SolrService.query("*:*",{fq: f,rows:rows})
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#FileDataObject'])}
      query = "{!join from=proxyFor_ssi to=identifier_ssim}#{f.join(' ')}"
      files = ActiveFedora::SolrService.query(query,rows:'999')
      proxies.each do |proxy|
        file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
        if file
          rels_int = file.fetch('rels_int_profile_tesim',[]).first
          props = rels_int ? JSON.load(rels_int) : {}
          props = props["#{proxy_uri}/content"] || {}
          props['pid'] = file['id']
          props['extent'] ||= file['extent_ssim'] if file['extent_ssim']
          proxy.merge!(props)
        end
      end
    end
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#Folder'])}
      query = "{!join from=id  to=belongsToContainer_ssi}#{f.join(' ')}"
      folder_counts = facets_for(query,:"facet.field" => "belongsToContainer_ssi",:"facet.limit" => '999')
      unless ( belongsToContainer = facet_to_hash(folder_counts["belongsToContainer_ssi"])).empty?
        proxies.each do |proxy|
          if proxy["type_ssim"].include?(RDF::NFO[:'#Folder'])
            proxy['extent'] ||= belongsToContainer[proxy['id']]
          end
        end
      end
    end
    if block_given?
      proxies.each &block
    else
      proxies
    end
  end
end