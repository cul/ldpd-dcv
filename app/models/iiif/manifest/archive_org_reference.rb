class Iiif::Manifest::ArchiveOrgReference < Iiif::BaseResource
  def initialize(id, solr_document)
    super(id, solr_document)
  end

  def label
    { en: [""] }
  end

  def summary
  end

  def metadata
    # metadata could be fetched from IA at https://archive.org/metadata/:id
  end

  def descriptors
  end

  def thumbnail
    thumbnail_url = Dcv::Utils::CdnUtils.image_service(@solr_document)&.thumbnail_url
    return { '@id' => thumbnail_url } if thumbnail_url
  end

  def as_json(opts = {})
    manifest = {}
    manifest['id'] = "https://iiif.archivelab.org/iiif/#{@id}/manifest.json"
    manifest['type'] = 'Manifest'
    manifest['thumbnail'] = thumbnail
    manifest['label'] = @solr_document['title']
    manifest.compact
  end

  def items
  end
end