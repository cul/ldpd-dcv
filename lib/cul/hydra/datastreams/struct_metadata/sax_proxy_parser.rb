class Cul::Hydra::Datastreams::StructMetadata::SaxProxyParser
  attr_reader :file_system, :graph_context_uri, :node_base_uri, :xml_io, :ns_prefix, :type

  def initialize(graph_context_uri:, xml_io:, file_system: false, ns_prefix: 'xmlns', dsid: 'structMetadata')
    @xml_io = xml_io
    @ns_prefix = ns_prefix || 'xmlns'
    @file_system = file_system
    @graph_context_uri = graph_context_uri
    @node_base_uri = graph_context_uri + "/#{dsid}"
  end

  def proxy_enumerator
    proxy_handler = ProxyHandler.new
    proxy_handler.file_system = self.file_system
    proxy_handler.graph_context_uri = self.graph_context_uri
    proxy_handler.node_base_uri = self.node_base_uri
    proxy_handler.ns_prefix = self.ns_prefix
    Enumerator.new do |yielder|
      proxy_handler.yielder = yielder
      Ox.sax_parse(proxy_handler, xml_io)
    end
  end

  def each &block
    proxy_handler = ProxyHandler.new
    proxy_handler.file_system = self.file_system
    proxy_handler.graph_context_uri = self.graph_context_uri
    proxy_handler.node_base_uri = self.node_base_uri
    proxy_handler.ns_prefix = self.ns_prefix
    if block
      proxy_handler.yielder = block
      Ox.sax_parse(proxy_handler, xml_io)
    else
      return Enumerator.new do |yielder|
        proxy_handler.yielder = yielder
        Ox.sax_parse(proxy_handler, xml_io)
      end
    end
  end

  class ProxyHandler < ::Ox::Sax
    CONTENTIDS = :'CONTENTIDS'
    LABEL = :'LABEL'
    NAME = :'NAME'
    ORDER = :'ORDER'

    def file_system= val
      @file_system = val
      @asset_proxy_type = @file_system ?
            NFO::FileDataObject : SC::Canvas
      @container_proxy_class = @file_system ?
            NFO::Folder : SC::Sequence
    end

    def graph_context_uri= val
      @graph_context_uri = val
    end

    def node_base_uri= val
      @node_base_uri = val
    end

    def ns_prefix= val
      @ns_prefix = val
      @element_name = :"#{@ns_prefix}:div"
      val
    end

    def yielder= val
      @yielder = val
    end

    def initialize
      super
      @ancestors = []
    end

    def start_element name
      @ancestors << @current if @current
      @current = { NAME => name }
    end

    def attr(name, value)
      @current[name] = value
      @current[:uri_label] = URI::DEFAULT_PARSER.escape(value) if name == LABEL
    end

    def end_element name
      if name == @element_name
        proxy_uri_chain = current_proxy_uri_chain
        proxy_resource_uri = proxy_uri_chain.pop
        proxy = base_document(@current[CONTENTIDS])
        proxy['id'] = proxy_resource_uri.to_s
        proxy['proxyIn_ssi'] = @graph_context_uri.to_s
        if @current[CONTENTIDS]
          proxy['proxyFor_ssi'] = RDF::URI(@current[CONTENTIDS]).to_s
        else
          # this is the existing behavior in 1.13.x
          proxy['proxyFor_ssi'] = proxy_resource_uri.to_s
        end
        if @ancestors.last and @ancestors.last[NAME] == @element_name
          proxy['belongsToContainer_ssi'] = proxy_uri_chain.last&.to_s
        end
        proxy['isPartOf_ssim'] = proxy_uri_chain.map(&:to_s) unless proxy_uri_chain.empty?
        proxy['index_ssi'] = @current[ORDER]
        proxy['label_ssi'] = @current[LABEL]
        @yielder.yield proxy
      end
      @current = @ancestors.pop
    end

    private
    def base_document(has_asset_type)
      if has_asset_type
        return {
          'type_ssim' => [
            RDF::ORE.Proxy.to_s,
            (@file_system ? RDF::NFO[:"#FileDataObject"].to_s : RDF::SC[:Canvas].to_s)
          ]
        }
      end
      {
        'type_ssim' => [
          RDF::ORE.Proxy.to_s,
          (@file_system ? RDF::NFO[:"#Folder"].to_s : RDF::SC[:Sequence].to_s)
        ]
      }
    end

    def ancestors
      nodes = Array(@ancestors) + [@current]
      nodes.inject([]) do |acc, node|
        if node && node[NAME] == @element_name
          acc << (node[:uri_label].present? ? node[:uri_label] : node[ORDER])
        end
        acc
      end
    end
    def current_proxy_uri_chain
      uris = []
      ancestors.inject(@node_base_uri) {|m,a| (uris << m + "/#{a}").last}
      uris
    end
    def current_proxy_uri
      # uri = segments.inject(base_uri) {|m,a| m/a}
      ancestors.inject(@node_base_uri) {|m,a| m + "/#{a}"}
    end
  end
end