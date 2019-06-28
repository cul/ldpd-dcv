module Dcv::ChildrenHelperBehavior

  include Dcv::CdnHelper
  include Dcv::SolrHelper

  CHILDREN_ACCESS = [
    'access_control_levels_ssim', 'access_control_permissions_bsi',
    'access_control_embargo_dtsi', 'access_control_locations_ssim',
    'access_control_affiliations_ssim', 'publisher_ssim'
  ].freeze
  CHILDREN_IDS = ['id', 'dc_identifier_ssim', 'identifier_ssim'].freeze
  CHILDREN_STRUC = (CHILDREN_IDS + CHILDREN_ACCESS + ['dc_type_ssm', 'datastreams_ssim','original_name_ssim']).freeze
  CHILDREN_MODEL = (CHILDREN_STRUC + ["active_fedora_model_ssi",'rels_int_profile_tesim','rft_id_ss','label_ssi']).freeze


  # Return the number from the specified field if greater than zero.
  # If the number indicated in the field is zero, attempt to count
  # archive.org identifiers instead.
  # @param args [Hash] feild helper method argumenthash defined by Blacklight
  # @return [Integer] displayable number of assets
  def asset_count_value(args)
    doc = args[:document]
    field_name = args[:field]
    field_value = doc[field_name].to_i
    (archive_org_id_for_document(doc) && field_value == 0) ? 1 : field_value
  end

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
    fl = CHILDREN_MODEL.dup
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
    child = {id: doc['id'], pid: doc['id'], thumbnail: get_asset_url(id: doc['id'], size: 768, type: 'full', format: 'jpg')}
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
      if (ActiveFedora.config.credentials[:datastreams_root].present? && base_rft = doc['rft_id_ss'])
        zoom = rels_int["info:fedora/#{child[:id]}/content"].fetch('foaf_zooming',['zoom']).first
        zoom = zoom.split('/')[-1]
        base_rft.sub!(/^info\:fedora\/datastreams/,ActiveFedora.config.credentials[:datastreams_root])
        base_rft = 'file:' + base_rft unless base_rft =~ /(file|https?)\:\//
        child[:rft_id] = CGI.escape(base_rft)
        child[:width] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('image_width',[0]).first.to_i
        child[:length] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('image_length',[0]).first.to_i
      end
    end
    child[:datastreams_ssim] = doc.fetch('datastreams_ssim', [])
    child[:publisher_ssim] = doc.fetch('publisher_ssim', [])
    accessControlFields(doc).each do |k, v|
      child[k.to_sym] = v
    end
    return child
  end

  def structured_children_from_fedora
      struct = Cul::Hydra::Fedora.ds_for_uri("info:fedora/#{@document['id']}/structMetadata")
      struct = Nokogiri::XML(struct.content)
      ns = {'mets'=>'http://www.loc.gov/METS/'}
      nodes = struct.xpath('//mets:div[@ORDER]', ns).sort {|a,b| a['ORDER'].to_i <=> b['ORDER'].to_i }

      counter = 1
      nodes = nodes.map do |node|
        node_id = (node['CONTENTIDS'])


        pid = identifier_to_pid(node_id)
        node_thumbnail = get_asset_url(id: pid, size: 256, type: 'full', format: 'jpg')

        if subsite_layout == 'durst'
          title = "Image #{counter}"
          counter += 1
          access_level = "Public Access"
        else
          title = node['LABEL']
          access_level = "Closed"
        end

        {
          id: node_id,
          pid: pid,
          order: node['ORDER'].to_i,
          title: title,
          thumbnail: node_thumbnail,
          active_fedora_model_ssi: 'GenericResource',
          access_control_levels_ssim: [access_level]
        }
      end
      nodes
  end

  def structured_children_from_solr
    fq = [
      "proxyIn_ssi:\"info:fedora/#{@document['id']}\"",
      "proxyFor_ssi:*"
    ]
    _params = {
      q: '*:*',
      fq: fq,
      qt: 'search',
      rows: 999999,
      facet: false
    }

    response = Blacklight.solr.get 'select', params: _params
    proxies = response['response']['docs']
    proxies = Hash[proxies.map {|proxy| [proxy['proxyFor_ssi'], proxy]}]

    _params[:q] = "{!join to=dc_identifier_ssim from=proxyFor_ssi}proxyIn_ssi:\"info:fedora/#{@document['id']}\""
    _params.delete(:fq)

    response = Blacklight.solr.get 'select', params: _params
    kids = response['response']['docs'].select { |doc| online_access_indicated?(doc) }
    return nil unless kids.present?
    kids.each do |kid|
      kid['proxy_id'] = kid['dc_identifier_ssim'].detect { |key| proxies[key] }
    end
    kids.sort_by! {|kid| proxies[kid['proxy_id']]['index_ssi'].to_i}
    order = 0
    kids.map do |kid|
      SolrDocument.new kid.merge({
        id: kid['id'],
        pid: kid['id'],
        order: (order += 1),
        title: proxies[kid['proxy_id']]['label_ssi'] || "Image #{order}",
        thumbnail: get_asset_url(id: kid['id'], size: 256, type: 'full', format: 'jpg')
      })
    end
  end

  def structured_children
    @structured_children ||= begin
      if @document['structured_bsi'] == true
        children = structured_children_from_solr || structured_children_from_fedora
      else
        children = document_children_from_model[:children]
        # just assign the order they came in, since there's no structure
        children.each_with_index {|child, ix| child[:order] = ix + 1}
      end

      # Inject types from solr, using id lookup
      child_ids = children.map {|child| child[:id]}
      child_results = Blacklight.solr.post 'select', :data => {
        :rows => child_ids.length,
        :fl => CHILDREN_MODEL.dup,
        :qt => 'search',
        :fq => [
          "dc_identifier_ssim:\"#{child_ids.join('" OR "')}\"",
        ]
      }

      identifiers_to_dc_types = {}
      identifiers_to_pids = {}
      identifiers_to_original_names = {}
      identifiers_to_datastreams = {}
      identifiers_to_access_control = {}
      identifiers_to_publishers = {}
      child_results['response']['docs'].each do |doc|
        doc['dc_identifier_ssim'].each do |dc_identifier|
          identifiers_to_dc_types[dc_identifier] = doc['dc_type_ssm'].first
          identifiers_to_pids[dc_identifier] = doc['id']
          identifiers_to_original_names[dc_identifier] = doc['original_name_ssim']
          identifiers_to_datastreams[dc_identifier] = doc['datastreams_ssim']
          identifiers_to_publishers[dc_identifier] = doc['publisher_ssim']
          identifiers_to_access_control[dc_identifier] = accessControlFields(doc)
        end
      end

      children.each do |child|
        child[:dc_type] = identifiers_to_dc_types[child[:id]] if identifiers_to_dc_types.key?(child[:id])
        child[:pid] = identifiers_to_pids[child[:id]] if identifiers_to_pids.key?(child[:id])
        child[:original_name_ssim] = identifiers_to_original_names[child[:id]]
        child[:datastreams_ssim] = identifiers_to_datastreams[child[:id]]
        child[:publisher_ssim] = identifiers_to_publishers[child[:id]]
        identifiers_to_access_control.fetch(child[:id], {}).each do |k, v|
          child[k.to_sym] = v if v
        end
      end

      children
    end
  end

  def has_closed_children?
    structured_children.detect { |child| !can_access_asset?(child) }
  end

  def has_open_children?
    structured_children.detect { |child| can_access_asset?(child) }
  end

  def archive_org_identifiers_as_children
    @archive_org_identifiers ||= begin
      order = 0
      kids = JSON.parse(@document.fetch('archive_org_identifiers_json_ss','[]'))
      if kids.blank? && @document['archive_org_identifier_ssi']
        kids << {
          'id' => @document['archive_org_identifier_ssi'],
          'displayLabel' => @document['title_display_ssm'].first
        }
      end
      kids.map do |arxv_obj|
        SolrDocument.new({
          id: arxv_obj['id'],
          dc_type: 'Text',
          order: (order += 1),
          title: arxv_obj['displayLabel'] || arxv_obj['id'],
          thumbnail: thumbnail_url('archive_org_identifier_ssi' => arxv_obj['id']),
          datastreams_ssim: [],
          active_fedora_model_ssi: 'ArchiveOrg',
          archive_org_identifier_ssi: arxv_obj['id'],
          access_control_levels_ssim: ['Public Access'],
          access_control_permissions_bsi: false
        })
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
          c = ('<td data-title="Name">'+download_link(node, label, ['fs-file',html_class_for_filename(node['label_ssi'])])+' '+
            link_to('<span class="glyphicon glyphicon-info-sign"></span>'.html_safe, url_to_item(node['pid'],{return_to_filesystem:request.original_url}), title: 'More information')+
            '</td>').html_safe
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
