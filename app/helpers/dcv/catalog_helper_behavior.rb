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
    @structured_children ||= begin
      if @document['structured_bsi'] == true
        struct = Cul::Scv::Fedora.ds_for_uri("info:fedora/#{@document['id']}/structMetadata")
        struct = Nokogiri::XML(struct.content)
        ns = {'mets'=>'http://www.loc.gov/METS/'}
        nodes = struct.xpath('//mets:div[@ORDER]', ns).sort {|a,b| a['ORDER'].to_i <=> b['ORDER'].to_i }

        nodes = nodes.map do |node|
          node_id = (node['CONTENTIDS'])

          node_thumbnail = resolve_thumb_url(id: node_id)
          {id: node_id, title: node['LABEL'], thumbnail: node_thumbnail, order: node['ORDER'].to_i}
        end
        nodes
      else
        nodes = document_children_from_model[:children]
        # just assign the order they came in, since there's no structure
        nodes.each_with_index {|node, ix| node[:order] = ix + 1}
        nodes
      end
    end
  end

  def parents(document=@document, extra_params={})
    fname = 'cul_member_of_ssim' #solr_name(:cul_member_of, :symbol)
    p_pids = Array.new(document[fname])
    p_pids.compact!
    p_pids.collect! {|p_pid| p_pid.split('/')[-1].sub(':','\:')}
    controller.get_solr_response_for_document_ids(p_pids, extra_params)[1]
  end

  def link_to_resource_in_context(document=@document)
    parents = parents(document)
    parents.collect do |parent|
      link_to(parent.fetch('title_display_ssm',[]).first, catalog_url(id:parent['id']))
    end
  end
end
