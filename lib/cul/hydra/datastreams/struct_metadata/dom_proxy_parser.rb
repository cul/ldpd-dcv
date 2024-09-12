class Cul::Hydra::Datastreams::StructMetadata::DomProxyParser
	attr_reader :file_system, :graph_context_uri, :node_base_uri, :ng_xml, :ns_prefix, :type

  def initialize(graph_context_uri:, ng_xml:, file_system: false, ns_prefix: 'xmlns', dsid: 'structMetadata')
  	@ng_xml = ng_xml
    @ns_prefix = ns_prefix || 'xmlns'
    @file_system = file_system
    @graph_context_uri = graph_context_uri
    @node_base_uri = graph_context_uri + "/#{dsid}"
  end

  def proxies
    xpath_query = "//#{ns_prefix}:div"
    divs = ng_xml.xpath(xpath_query, ng_xml.namespaces)

    divs.collect do |div|
      proxy_uri_chain = proxy_uri_chain_for(div)
      proxy_resource_uri = proxy_uri_chain.pop
      if div['CONTENTIDS']
        subclass = file_system ?
          NFO::FileDataObject : SC::Canvas
        proxy = subclass.new(proxy_resource_uri, graph_context_uri)
        proxy.proxyFor = RDF::URI(div['CONTENTIDS'])
      else
        subclass = file_system ?
          NFO::Folder : SC::Sequence
        proxy = subclass.new(proxy_resource_uri, graph_context_uri)
      end
      if div.parent and div.parent.name == 'div'
        proxy.belongsToContainer = proxy_uri_for(div.parent)
      end
      proxy.isPartOf = proxy_uri_chain unless proxy_uri_chain.empty?
      proxy.index = div['ORDER']
      proxy.label = div['LABEL']
      proxy
    end
  end

  private
  def ancestors(node)
    current = node
    labels = []
    while (current.name == 'div')
      label = URI::DEFAULT_PARSER.escape(current['LABEL'])
      label = URI::DEFAULT_PARSER.escape(current['ORDER']) if label.blank?
      labels.unshift label
      current = current.parent
    end
    labels
  end
  def proxy_uri_chain_for(node)
    uris = []
    ancestors(node).inject(node_base_uri) {|m,a| (uris << m + "/#{a}").last}
    uris
  end
  def proxy_uri_for(node)
    # uri = segments.inject(base_uri) {|m,a| m/a}
    ancestors(node).inject(node_base_uri) {|m,a| m + "/#{a}"}
  end
end