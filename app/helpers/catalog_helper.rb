module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include Dcv::AbilityHelperBehavior
  include Dcv::FieldSetsHelperBehavior
  include Dcv::CatalogHelperBehavior
  include Dcv::IframeHelperBehavior
  include Dcv::OreProxiesHelperBehavior
  include Dcv::StructMetadataHelperBehavior
  include Dcv::Resources::RelsIntBehavior

  def has_thumbnail? document
    true
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

  def proxies(opts=params, &block)
    proxy_in = opts[:id]
    proxy_uri = "info:fedora/#{proxy_in}"
    proxy_id = opts[:proxy_id]
    proxy_in_query = "proxyIn_ssi:#{RSolr.solr_escape(proxy_uri).gsub(' ', '%20')}"
    f = [proxy_in_query]
    if proxy_id
      f << "belongsToContainer_ssi:#{RSolr.solr_escape(proxy_id).gsub(' ', '%20')}"
    else
      f << "-belongsToContainer_ssi:*"
    end
    rows = opts[:limit] || '999'
    local_params = { q: "*:*", defType: 'lucene', qt: "search", fq: f, rows:rows }
    _response, proxies = controller.search_service.search_results { |b| b.merge(local_params) }
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#FileDataObject'])}
      if proxy_id
        query = "{!join from=proxyFor_ssi to=identifier_ssim}#{f.last}"
      else
        query = "{!join from=proxyFor_ssi to=identifier_ssim}#{proxy_in_query}"
      end
      file_members = "cul_member_of_ssim:#{RSolr.solr_escape(proxy_uri).gsub(' ', '%20')}"
      local_params = { q: query, defType: 'lucene', qt: "search", fq: [file_members], rows: '999' }
      _response, files = controller.search_service.search_results { |b| b.merge(local_params) }
      proxies.each do |proxy|
        file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
        if file
          rels_int = file.fetch('rels_int_profile_tesim',[]).first
          props = rels_int ? JSON.load(rels_int) : {}
          props = props["#{proxy_uri}/content"] || {}
          props['pid'] = file['id']
          props['extent'] ||= file['extent_ssim'] if file['extent_ssim']
          proxy.merge_source!(props)
        end
      end
    end
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#Folder'])}
      query = "{!join from=id  to=belongsToContainer_ssi}#{f.join(' ')}"
      folder_counts = facets_for(query,:"facet.field" => "belongsToContainer_ssi",:"facet.limit" => '999')
      unless ( belongsToContainer = facet_to_hash(folder_counts["belongsToContainer_ssi"])).empty?
        proxies.each do |proxy|
          if proxy["type_ssim"].include?(RDF::NFO[:'#Folder']) && !proxy['extent']
            proxy.merge_source!(extent: belongsToContainer[proxy['id']])
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
