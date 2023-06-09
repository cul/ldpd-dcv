class Iiif::Collection < Iiif::BaseResource
  COLLECTION_PROXY_TYPE = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#Folder"
  attr_reader :route_helper, :solr_document, :children_service, :proxy_path, :part_of_id, :ability_helper

  def initialize(id:, solr_document:, children_service:, route_helper:, ability_helper:, **args)
    super(id: id, solr_document: solr_document)
    @children_service = children_service
    @route_helper = route_helper
    @proxy_path = @id.split(/\/collection\/?/)[1]
    @part_of_id = @id.split('/')[0...-1].join('/') unless (@id =~ /collection\/?$/)
  end

  def metadata
    # TODO: pass the show field definitions in from the controller context
    # Should this class be a presenter rather than a model?
    fields = []

    if @solr_document['lib_repo_full_ssim'].present?
      fields << {
          label: { en: ['Location'] },
          value: { en: Array(@solr_document['lib_repo_full_ssim']) }
      }
    end
    fields
  end

  def items
    # look up context proxy if proxy path is not blank
    if proxy_path.present?
      container_proxy_id = "info:fedora/#{solr_document.id}/structMetadata/#{proxy_path}"
      # need to make sure collection has partOf property set appropriately to parent collection URI
    end

    contained_items = proxied_items([self.as_json], container_proxy_id)
    contained_items = archive_org_items if contained_items.blank?
    contained_items
  end

  def proxied_items(part_of_json, container_proxy_id)
    # get structured children proxies for context
    children = children_service.from_contained_structure_proxies(solr_document, container_proxy_id, include_folders: true)
    # items are either collections (if proxy) or manifest
    children.map do |child_doc|
      part_of_json ||= [self.as_json]
      if child_doc['type_ssim']&.include?(COLLECTION_PROXY_TYPE)
        # do collection
        child_id = subcollection_id(child_doc['proxyFor_ssi'])
        Iiif::Collection.new(id: child_id, solr_document: solr_document, children_service: children_service, route_helper: route_helper, ability_helper: ability_helper).tap {|c| c.part_of_json = part_of_json}
      else
        # do manifest
        child_id = manifest_id(child_doc)
        Iiif::Manifest.new(id: child_id, solr_document: child_doc, children_service: children_service, route_helper: route_helper, part_of: part_of_json, ability_helper: ability_helper)
      end
    end
  end

  def archive_org_items
    children = children_service.from_archive_org_identifiers(solr_document)
    children&.map {|child_doc| Iiif::Manifest::ArchiveOrgReference.new(id: child_doc.id, solr_document: child_doc) }
  end

  def as_json(opts = {})
    collection = {}
    collection["@context"] = ["http://iiif.io/api/auth/2/context.json", "http://iiif.io/api/presentation/3/context.json"] if opts[:include]&.include?(:context)
    collection['id'] = @id
    collection['type'] = 'Collection'
    collection['label'] = label
    collection['behavior'] = ['multi-part']
    if opts[:include]&.include?(:metadata)
      collection['metadata'] = metadata
    end
    collection['rights'] = @solr_document['copyright_statement_ssi'] if @solr_document['copyright_statement_ssi'].present?
    if @solr_document['lib_acknowledgment_notes_ssm'].present?
      collection['requiredStatement'] = {
        label: { en: ['Acknowledgment'] },
        value: { en: Array(@solr_document['lib_acknowledgment_notes_ssm']) }
      }
    end
    if @solr_document['fedora_pid_uri_ssi']
      (collection["seeAlso"] ||= []) << {
        "id": route_helper.item_mods_url(id: @solr_document.id, format: 'xml'),
        "type": "Dataset",
        "label": { "en": [ "Bibliographic Description in MODS XML" ] },
        "format": "text/xml",
        "schema": "http://www.loc.gov/mods/v3",
        "profile": "https://example.org/profiles/bibliographic"
      }
    end
    collection['partOf'] = part_of
    if opts[:include]&.include?(:items)
      collection['items'] = items.map(&:as_json)
      collection['start'] = collection['items'].first.slice('id', 'type') unless collection['items'].blank?
    end
    collection.compact
  end

  def part_of_json=(val)
    @part_of_json = Array(val)
  end

  def part_of
    return nil unless part_of_id
    @part_of_json ||= [
      Iiif::Collection.new(
        id: part_of_id, solr_document: solr_document, children_service: children_service,
        route_helper: route_helper, reading_room: reading_room
      ).as_json
    ]
  end

  def subcollection_id(container_id)
    return nil unless container_id
    collection_registrant, collection_doi = @solr_document.doi_identifier.split('/')
    proxy_path_value = container_id.split(/\/structMetadata\/?/)[1]
    collection_params = {collection_registrant: collection_registrant, collection_doi: collection_doi}
    collection_params[:proxy_path] = CGI.unescape(proxy_path_value) if proxy_path_value.present?
    collection_id = route_helper.iiif_collection_url(collection_params)
  end

  def manifest_id(child_doc)
    collection_registrant, collection_doi = @solr_document.doi_identifier.split('/')
    manifest_registrant, manifest_doi = child_doc.doi_identifier&.split('/')
    routing_params = {
      collection_registrant: collection_registrant, collection_doi: collection_doi,
      manifest_registrant: manifest_registrant, manifest_doi: manifest_doi
    }
    route_helper.iiif_collected_manifest_url(routing_params)    
  end

  def label
    #TODO: if id has a proxy path, need to fetch actual folder doc
    value = CGI.unescape(proxy_path) if proxy_path
    value ||= @solr_document['title_display_ssm'][0] if @solr_document['title_display_ssm'].present?
    value ||= @solr_document['title'] || @solr_document['label_ssi']
    { en: [value] }
  end
end