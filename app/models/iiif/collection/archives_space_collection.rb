class Iiif::Collection::ArchivesSpaceCollection
  attr_reader :id, :archives_space_id, :children_service, :route_helper, :ability_helper
  ID_MATCH = /\/aspace\/([A-Za-z0-9\-]+)\/collection/
  SOLR_PARENT_FIELD = :rel_other_archives_space_parent_identifier_ssim

  def initialize(id:, children_service:, route_helper:, ability_helper:, **args)
    @id = id
    @archives_space_id = ID_MATCH.match(@id.to_s)&.[](1)
    @children_service = children_service
    @route_helper = route_helper
    @ability_helper = ability_helper
  end

  def metadata
    # TODO: decide on field definitions to pull from child items
    []
  end

  # get items from Solr by querying for ASpace ID
  def items
    # memoize because will need to call for metadata and for item listing
    @solr_documents ||= children_service.from_aspace_parent(archives_space_id)
    # must also get multiple pages of items
    # if these requests are onerous, may need to refactor to stream some or all of json response back
    #TODO map these documents to manifest constructs, with identifiers indicating containment
    []
  end

  # this is used when constructing metadata from a contained manifest
  def items=(solr_documents)
    @solr_documents = solr_documents
  end

  def rights
    nil
  end

  def required_statement
    nil
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
    collection['rights'] = rights
    collection['requiredStatement'] = required_statement
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
    nil
  end

  # do not expect hierarchy of ASpace collections
  def subcollection_id(container_id)
    nil
  end

  def manifest_id(child_doc)
    manifest_registrant, manifest_doi = child_doc.doi_identifier&.split('/')
    routing_params = {
      archives_space_id: @archives_space_id, manifest_registrant: manifest_registrant, manifest_doi: manifest_doi
    }
    route_helper.iiif_aspace_collected_manifest_url(routing_params)
  end

  def label
    #TODO: label should come from collections and archival context of included manifests
    # alternately, could query/cache ACFA
    { en: [] }
  end

  def collection_for?(solr_document)
    return false unless solr_document

    solr_document[SOLR_PARENT_FIELD]&.include(@archives_space_id)
  end
end