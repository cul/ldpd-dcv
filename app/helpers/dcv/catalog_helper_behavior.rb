module Dcv::CatalogHelperBehavior
  def url_for_children_data(per_page=nil)
    opts = {id: params[:id], controller: :children}
    opts[:per_page] = per_page || 4
    opts[:protocol] = (request.ssl?) ? 'https' : 'http'
    url_for(opts)
  end

  def format_value_transformer(value)
    transformation = {'resource' => 'File Asset', 'multipartitem' => 'Item', 'collection' => 'Collection'}
    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def structured_children
    if @document['structured_bsi'] == true
      struct = Cul::Scv::Fedora.ds_for_uri("info:fedora/#{@document['id']}/structMetadata")
      struct = Nokogiri::XML(struct.content)
      ns = {'mets'=>'http://www.loc.gov/METS/'}
      nodes = struct.xpath('//mets:div[@ORDER]').sort {|a,b| a['ORDER'].to_i <=> b['ORDER'].to_i }

      nodes = nodes.map {|node| {id: CGI.escape(node['CONTENTIDS']), title: node['LABEL'], order: node['ORDER'].to_i}}
      nodes
    else
      []
    end
  end

end
