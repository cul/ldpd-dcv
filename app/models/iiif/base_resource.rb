class Iiif::BaseResource
  attr_reader :id, :solr_document

  def initialize(id:, solr_document:, **args)
    @id = id
    @solr_document = solr_document
  end

  def fedora_pid
    @fedora_pid ||= @solr_document[:fedora_pid_uri_ssi]&.sub('info:fedora/','') || @solr_document[:id]
  end

  def doi
    @doi ||= @solr_document[:ezid_doi_ssim].first&.sub(/^doi:/,'')
  end

  def as_json(opts = {})
    {}
  end

  def to_h(opts = {})
    as_json(opts)
  end

  def to_json(opts = {})
    JSON.pretty_generate(as_json(opts))
  end

end