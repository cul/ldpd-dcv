# -*- encoding : utf-8 -*-
class Dcv::Solr::ChildrenAdapter
  include Dcv::AccessLevels
  attr_reader :searcher, :authorizer, :title_field
  # legacy searcher is controller or helper, needs to define .search_results
  # legacy authorizer is helper
  # title field given by document_show_link_field() where defined
  def initialize(searcher, authorizer, title_field = 'title_ssm')
    @searcher = searcher
    @authorizer = authorizer
    @title_field = title_field
  end

  def folder_document_from_proxy(proxy_document, parent_document, order = nil)
    local_path = proxy_document['id'].split('/structMetadata/')[1]
    proxy_document.merge_source({
      'id' => "#{parent_document.doi_identifier}/collection/#{local_path}",
      'dc_type' => 'Collection',
      'order' => order,
      'title' => proxy_document['label_ssi']
    })
  end

  def update_child_document_from_proxy!(proxy_document, child_document, order = nil)
    title_value = proxy_document['label_ssi'] || Array(child_document[title_field]).first || "Image #{order}"
    child_document.merge_source!({
      'pid' => child_document['id'],
      'dc_type' => Array(child_document['dc_type_ssm']).first,
      'title' => title_value,
      'belongsToContainer_ssi' => proxy_document['belongsToContainer_ssi'],
      'order' => order,
      'thumbnail' => Dcv::Utils::CdnUtils.asset_url(id: child_document['id'], size: 256, type: 'full', format: 'jpg')
    })
  end

  def from_all_structure_proxies(parent_document, opts = {})
    proxy_params = {
      q: "proxyIn_ssi:\"info:fedora/#{parent_document['id']}\"",
      rows: 999999
    }
    from_queried_structure_proxies(parent_document, opts.merge(proxy_params))
  end

  def from_contained_structure_proxies(parent_document, container_proxy_id, opts = {})
    proxy_params = {
      rows: 999999
    }
    if container_proxy_id
      proxy_params[:q] = "belongsToContainer_ssi:\"#{container_proxy_id}\""
    else
      proxy_params[:q] = "proxyIn_ssi:\"info:fedora/#{parent_document['id']}\""
      proxy_params[:fq] = "!belongsToContainer_ssi:*"
    end
    from_queried_structure_proxies(parent_document, opts.merge(proxy_params))
  end

  def from_queried_structure_proxies(parent_document, opts = {})
    local_params = {
      q: opts.fetch(:q, '*:*'),
      qt: 'search',
      rows: opts.fetch(:rows, 0),
      fq: Array(opts.fetch(:fq, nil)).first,
      fl: "*,resources:[subquery]",
      :"resources.q" => "{!terms f=dc_identifier_ssim v=$row.proxyFor_ssi}",
      facet: false
    }
    merge_proc = Proc.new { |b| b.merge(local_params) }
    response, proxy_docs = searcher.search_results({}, &merge_proc)
    order = 0
    folders = []
    children = []
    indexed = true;
    proxy_docs.each do |proxy_doc|
      resource_response = proxy_doc._source.delete('resources')
      if proxy_doc['type_ssim'].include?(Iiif::Collection::COLLECTION_PROXY_TYPE) and opts[:include_folders]
        order += 1
        folders << folder_document_from_proxy(proxy_doc, parent_document, order)
      else
        child_source = resource_response["docs"]&.first
        next unless child_source && authorizer.online_access_indicated?(child_source)
        indexed &= proxy_doc['index_ssi']
        child_doc = SolrDocument.new(child_source)
        update_child_document_from_proxy!(proxy_doc, child_doc, proxy_doc['index_ssi'].to_i)
        children << child_doc
      end
    end
    if indexed && children.present?
      children.sort_by! {|child| child['order']}
      children.each do |child|
        order += 1
        child._source['order'] = order
      end
    end
    folders.concat children
  end

  def from_unordered_membership(parent_document, _opts = {})
    fq = [
      "cul_member_of_ssim:\"info:fedora/#{parent_document['id']}\""
    ]
    local_params = {
      q: '*:*',
      fq: fq,
      qt: 'search',
      rows: 999999,
      facet: false
    }

    merge_proc = Proc.new { |b| b.merge(local_params) }
    response, docs = searcher.search_results({}, &merge_proc)
    docs
  end

  def from_archive_org_identifiers(parent_document, _opts = {})
    order = 0
    kids = JSON.parse(parent_document.fetch('archive_org_identifiers_json_ss','[]'))
    if kids.blank? && parent_document.archive_org_identifier
      kids << {
        'id' => parent_document.archive_org_identifier,
        'displayLabel' => parent_document['title_display_ssm'].first
      }
    end
    kids.map do |arxv_obj|
      SolrDocument.new({
        id: arxv_obj['id'],
        dc_type: 'Text',
        order: (order += 1),
        title: arxv_obj['displayLabel'] || arxv_obj['id'],
        thumbnail: Dcv::Utils::CdnUtils.image_service('archive_org_identifier_ssi' => arxv_obj['id']).thumbnail_url,
        datastreams_ssim: [],
        active_fedora_model_ssi: 'ArchiveOrg',
        archive_org_identifier_ssi: arxv_obj['id'],
        access_control_levels_ssim: [ACCESS_LEVEL_PUBLIC],
        access_control_permissions_bsi: false
      })
    end
  end
end