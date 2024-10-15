module Dcv::ChildrenHelperBehavior
  include Dcv::CdnHelper
  include Dcv::AbilityHelperBehavior

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
    children = {parent_id: parent_document[:id], children: []}
    rows = opts.fetch(:per_page, 10).to_i
    page = opts.fetch(:page, 0).to_i
    offset = page * rows
    fl = CHILDREN_MODEL.dup
    title_field = 'title_ssm'
    fl << title_field.dup
    opts = {fl: fl.join(','), raw: true, rows: rows, start: offset}.merge(opts)
    response, docs = solr_children_adapter.from_paged_membership(parent_document, opts)
    children[:pages] = (response['numFound'].to_f / rows).ceil
    children[:page] = page
    children[:per_page] = rows
    children[:count] = response['numFound'].to_i
    docs.map do |doc|
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

  def solr_children_adapter
    @children_adapter ||= begin
      searcher = (defined? :controller) ? controller : self
      authorizer = self
      Dcv::Solr::ChildrenAdapter.new(searcher, authorizer, "title_ssm")
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

  def download_link(node, label, attr_class)
    args = {catalog_id: node['pid'], filename:node['label_ssi'], bytestream_id: 'content'}
    href = bytestream_content_url(args) #, "download")
    content_tag(:a, label, href: href, class: attr_class)
  end

  def is_file_system?(document)
    return false unless document
    document['active_fedora_model_ssi'] == 'Collection' && document['dc_type_sim']&.include?('FileSystem')
  end
end
