module Dcv::ChildrenHelperBehavior

  include Dcv::CdnHelper

  def document_children_from_model(opts={})
    # get the model class
    klass = @document['active_fedora_model_ssi'].constantize
    # get a relation for :parts
    reflection = klass.reflect_on_association(:parts)
    association = reflection.association_class.new(IdProxy.new(@document[:id]), reflection)
    children = {parent_id: @document[:id], children: []}
    children[:per_page] = opts.fetch(:per_page, 10).to_i
    children[:page] = opts.fetch(:page, 0).to_i
    offset = children[:per_page] * children[:page]
    rows = children[:per_page]
    fl = ['id',"active_fedora_model_ssi",'dc_identifier_ssim','dc_type_ssm','identifier_ssim','rels_int_profile_tesim','rft_id_ss','label_ssi']
    title_field = nil
    begin
      fl << (title_field = document_show_link_field).to_s
    rescue
    end
    opts = {fl: fl.join(','), raw: true, rows: rows, start: offset}.merge(opts)
    response = association.load_from_solr(opts)['response'];
    children[:pages] = (response['numFound'].to_f / rows).ceil
    children[:page] = children[:page]
    children[:count] = response['numFound'].to_i
    response['docs'].map do |doc|
      children[:children] << child_from_solr(doc)
    end
    children
  end

  def child_from_solr(doc)
    title_field = nil
    begin
      fl << (title_field = document_show_link_field).to_s
    rescue
    end
    child = {id: doc['id'], thumbnail: get_asset_url(id: doc['id'], size: 768, type: 'scaled', format: 'jpg')}
    if title_field
      title = doc[title_field.to_s]
      title = title.first if title.is_a? Array
      child[:title] = title
    end
    if doc["active_fedora_model_ssi"] == 'GenericResource'
      child[:contentids] = doc['dc_identifier_ssim']
      rels_int = JSON.load(doc.fetch('rels_int_profile_tesim',[]).join(''))
      unless rels_int.blank?
        #child[:rels_int] = rels_int
        width = rels_int["info:fedora/#{child[:id]}/content"].fetch('image_width',[0]).first.to_i
        length = rels_int["info:fedora/#{child[:id]}/content"].fetch('image_length',[0]).first.to_i
        child[:width] = width if width > 0
        child[:length] = length if length > 0
      end
      if (base_rft = doc['rft_id_ss'])
        zoom = rels_int["info:fedora/#{child[:id]}/content"].fetch('foaf_zooming',['zoom']).first
        zoom = zoom.split('/')[-1]
        base_rft.sub!(/^info\:fedora\/datastreams/,ActiveFedora.config.credentials[:datastreams_root])
        base_rft = 'file:' + base_rft unless base_rft =~ /(file|https?)\:\//
        child[:rft_id] = CGI.escape(base_rft)
        puts rels_int.inspect
        child[:width] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('image_width',[0]).first.to_i
        child[:length] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('image_length',[0]).first.to_i
      end
    end
    return child
  end

  def structured_children
    @structured_children ||= begin
      if @document['structured_bsi'] == true
        struct = Cul::Hydra::Fedora.ds_for_uri("info:fedora/#{@document['id']}/structMetadata")
        struct = Nokogiri::XML(struct.content)
        ns = {'mets'=>'http://www.loc.gov/METS/'}
        nodes = struct.xpath('//mets:div[@ORDER]', ns).sort {|a,b| a['ORDER'].to_i <=> b['ORDER'].to_i }

        counter = 1
        nodes = nodes.map do |node|
          node_id = (node['CONTENTIDS'])


          node_thumbnail = get_resolved_asset_url(id: node_id, size: 256, type: 'scaled', format: 'jpg')

          if subsite_layout == 'durst'
            title = "Image #{counter}"
            counter += 1
          else
            title = node['LABEL']
          end

          {id: node_id, title: title, thumbnail: node_thumbnail, order: node['ORDER'].to_i}
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

  def url_to_proxy(opts)
    method = opts[:proxy_id] ? "#{controller_name}_proxy_url" : "#{controller_name}_url"
    method = "restricted_" + method if controller.restricted?
    method = method.to_sym
    #opts = opts.merge(proxy_id:opts[:proxy_id].sub('.','%2E')) if opts[:proxy_id]
    send(method, opts.merge(label:nil))
  end
  def url_to_preview(pid)
    method = "#{controller_name}_preview_url"
    method = "restricted_" + method if controller.restricted?
    method = method.to_sym
    send method, id: pid
  end
  def url_to_item(pid,additional_params={})
    method = "#{controller_name}_url"
    method = "restricted_" + method if controller.restricted?
    method = method.to_sym
    send method, {id: pid}.merge(additional_params)
  end
  def proxy_node(node)
    filesize = node['extent'] ? simple_proxy_extent(node).html_safe : ''
    label = node['label_ssi']
    if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
      # file
      if node['pid'] 
        content_tag(:tr,nil) do
          c = ('<td data-title="Info" class="text-center">' +
            link_to('<span class="glyphicon glyphicon-info-sign"></span>'.html_safe, url_to_item(node['pid'],{return_to_filesystem:request.original_url}), title: 'Item permanent link') +
            '</td>').html_safe
          c += ('<td data-title="Name">' + download_link(node, label, ['fs-file',html_class_for_filename(node['label_ssi'])]) + '</td>').html_safe
          c += ('<td data-title="Size" data-sort-value="'+node['extent'].join(",").to_s+'">'+filesize+'</td>').html_safe
          #c += content_tag(:a, 'Preview', href: '#', 'data-url'=>url_to_preview(node['pid']), class: 'preview') do 
          #  content_tag(:i,nil,class:'glyphicon glyphicon-info-sign')
          #end
          c
        end
      end
    else
      # folder
      content_tag(:tr, nil) do
        c = ('<td data-title="Name">'+link_to(label, url_to_proxy({id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']}), class: 'fs-directory')+'</td>').html_safe
        c += ('<td data-title="Size" data-sort-value="'+node['extent'].to_s+'">'+filesize+'</td>').html_safe
        #content_tag(:a, label, href: url_to_proxy({id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']}))
      end
    end
  end
  def simple_proxy_extent(node)
    extent = Array(node['extent']).first || '0'
    if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
      extent = extent.to_i
      if extent > 0
        pow = Math.log(extent,1000).floor
        pow = 3 if pow > 3
        pow = 0 if pow < 0
      else
        pow = 0
      end
      unit = ['B','KB','MB','GB'][pow]
      "#{extent.to_i/(1000**pow)} #{unit}"
    else
      "#{extent.to_i} items"
    end
  end
  def download_link(node, label, attr_class)
    args = {catalog_id: node['pid'], filename:node['label_ssi'], bytestream_id: 'content'}
    href = bytestream_content_url(args) #, "download")
    content_tag(:a, label, href: href, class: attr_class)
  end

  #TODO: replace this with Cul::Hydra::Fedora::FakeObject
  class IdProxy < Cul::Hydra::Fedora::DummyObject
    def internal_uri
      @uri ||= "info:fedora/#{@pid}"
    end
  end
end
