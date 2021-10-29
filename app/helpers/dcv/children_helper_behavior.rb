module Dcv::ChildrenHelperBehavior
  include Dcv::AccessLevels

  include Dcv::CdnHelper
  include Dcv::SolrHelper

  CHILDREN_ACCESS = [
    'access_control_levels_ssim', 'access_control_permissions_bsi',
    'access_control_embargo_dtsi', 'access_control_locations_ssim',
    'access_control_affiliations_ssim', 'publisher_ssim'
  ].freeze
  CHILDREN_IDS = ['id', 'dc_identifier_ssim', 'identifier_ssim'].freeze
  CHILDREN_STRUC = (CHILDREN_IDS + CHILDREN_ACCESS + ['dc_type_ssm', 'datastreams_ssim','original_name_ssim']).freeze
  CHILDREN_MODEL = (CHILDREN_STRUC + ['active_fedora_model_ssi','rels_int_profile_tesim','label_ssi','lib_item_in_context_url_ssm']).freeze


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

  def document_children_from_model(parent_document = @document, opts={})
    # get the model class
    klass = parent_document['active_fedora_model_ssi'].constantize
    # get a relation for :parts
    reflection = klass.reflect_on_association(:parts)
    association = reflection.association_class.new(IdProxy.new(parent_document[:id]), reflection)
    children = {parent_id: parent_document[:id], children: []}
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
      children[:children] << child_from_solr(doc, title_field)
    end
    children
  end

  def child_from_solr(doc, title_field = nil)
    child = {id: doc['id'], pid: doc['id'], thumbnail: get_asset_url(id: doc['id'], size: 768, type: 'full', format: 'jpg')}
    if title_field
      title = doc[title_field.to_s]
      title = title.first if title.is_a? Array
      child[:title] = title
    end
    if doc["active_fedora_model_ssi"] == 'GenericResource'
      child[:contentids] = doc['dc_identifier_ssim']
      rels_int = JSON.load(doc.fetch('rels_int_profile_tesim',[]).join(''))

      dimension_ref = "info:fedora/#{child[:id]}/content"
      unless rels_int.blank?
        width = rels_int[dimension_ref]&.fetch('image_width',[0])
        width = width.blank? ? 0 : width.first.to_i
        length = rels_int[dimension_ref]&.fetch('image_length',[0])
        length = length.blank? ? 0 : length.first.to_i
        child[:width] = width if width > 0
        child[:length] = length if length > 0
      end
    end
    child[:datastreams_ssim] = doc.fetch('datastreams_ssim', [])
    child[:publisher_ssim] = doc.fetch('publisher_ssim', [])
    child[:lib_item_in_context_url_ssm] = doc.fetch('lib_item_in_context_url_ssm', [])
    child[:dc_type] = doc.fetch('dc_type_ssm', []).first

    access_control_fields(doc).each do |k, v|
      child[k.to_sym] = v
    end
    return child
  end

  def structured_children_from_fedora(parent_document)
      struct = Cul::Hydra::Fedora.ds_for_uri("info:fedora/#{parent_document['id']}/structMetadata")
      struct = Nokogiri::XML(struct.content)
      ns = {'mets'=>'http://www.loc.gov/METS/'}
      nodes = struct.xpath('//mets:div[@ORDER]', ns).sort {|a,b| a['ORDER'].to_i <=> b['ORDER'].to_i }

      counter = 1
      nodes.map! do |node|
        counter += 1
        {
          id: node['CONTENTIDS'],
          order: node['ORDER'].to_i,
          title: (subsite_layout == 'durst') ? "Image #{counter}" : node['LABEL'],
          access_control_levels_ssim: (subsite_layout == 'durst') ? ACCESS_LEVEL_PUBLIC : ACCESS_LEVEL_CLOSED
        }
      end

      node_ids = nodes.map { |node| node[:id] }

      # Inject types from solr, using id lookup
      child_results = post_to_repository 'select', {
        :rows => node_ids.length,
        :fl => CHILDREN_MODEL.dup,
        :qt => 'search',
        :fq => [
          "dc_identifier_ssim:\"#{node_ids.join('" OR "')}\"",
        ]
      }

      child_identifiers_to_documents = {}
      children = child_results['response']['docs']
      children.each do |doc|
        doc['dc_identifier_ssim'].each do |dc_identifier|
          child_identifiers_to_documents[dc_identifier] = doc
        end
      end

      nodes.map do |node|
        doc = child_identifiers_to_documents[node[:id]] || {}
        doc[:order] = node['ORDER'].to_i,
        doc[:access_control_levels_ssim] ||= Array(node[:access_control_levels_ssim])
        doc[:pid] = doc[:id]
        doc[:dc_type] = Array(doc['dc_type_ssm']).first
        doc[:thumbnail] = get_asset_url(id: doc[:id], size: 256, type: 'full', format: 'jpg')
        doc[:title] = (node[:title].blank? ? Array(doc['title_ssm']).first : node[:title])
        doc
      end.map(&:with_indifferent_access)
  end

  def solr_children_adapter
    @children_adapter ||= begin
      searcher = (defined? :controller) ? controller : self
      authorizer = self
      title_field = (defined? :document_show_link_field) ? document_show_link_field : "title_ssm"
      Dcv::Solr::ChildrenAdapter.new(searcher, authorizer, title_field)
    end
  end

  def structured_children_from_solr(parent_document)
    solr_children_adapter.from_all_structure_proxies(parent_document)
  end

  def post_to_repository(path, params)
    controller.repository.send_and_receive(path, params)
  end

  def archive_org_identifiers_as_children(parent_document = @document)
    @archive_org_identifiers ||= solr_children_adapter.from_archive_org_identifiers(parent_document)
  end

  def url_to_proxy(opts)
    method = controller.restricted? ? "proxies_restricted_#{controller_name}_url" : "proxies_#{controller_name}_url"
    method = method.to_sym
    send(method, opts.merge(label:nil))
  end

  def url_to_preview(pid)
    method = controller.restricted? ? "preview_restricted_#{controller_name}_url" : "preview_#{controller_name}_url"
    method = method.to_sym
    send method, id: pid
  end

  def url_to_item(pid,additional_params={})
    method = controller.restricted? ? "restricted_#{controller_name}_show_url" : "#{controller_name}_show_url"
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
            link_to('<span class="fa fa-info-circle"></span>'.html_safe, url_to_item(node['pid'],{return_to_filesystem:request.original_url}), title: 'More information')+
            '</td>').html_safe
          c += ('<td data-title="Size" data-sort-value="'+node['extent'].join(",").to_s+'">'+filesize+'</td>').html_safe
          c
        end
      end
    else
      # folder
      content_tag(:tr, nil) do
        c = ('<td data-title="Name">'+link_to(label, url_to_proxy({id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']}), class: 'fs-directory')+'</td>').html_safe
        c += ('<td data-title="Size" data-sort-value="'+node['extent'].to_s+'">'+filesize+'</td>').html_safe
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
