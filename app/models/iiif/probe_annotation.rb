# frozen_string_literal: true

class Iiif::ProbeAnnotation
  attr_reader :id, :canvas, :route_helper, :ability_helper

  def initialize(canvas, route_helper:, ability_helper:)
    @canvas = canvas
    @route_helper = route_helper
    @ability_helper = ability_helper
  end

  def required?
    access_service.required?
  end

  def to_h
    annotation = IIIF_TEMPLATES['painting_annotation'].deep_dup
    routing_opts = canvas.routing_opts.merge(id: 'painting')
    annotation['id'] = route_helper.iiif_annotation_url(routing_opts)
    catalog_id = canvas.solr_document.id
    bytestream_id = Dcv::Utils::UrlUtils.preferred_content_bytestream(canvas.solr_document)
    annotation['body'] = {
      'type' => canvas.canvas_type,
      'id' => route_helper.bytestream_resource_url(catalog_id: catalog_id, bytestream_id: bytestream_id),
      'service' => [access_service.to_h]
    }
    annotation['target'] = canvas.id
    annotation
  end

  def access_service
    @probe_service ||= Iiif::Authz::V2::ProbeService.new(canvas, route_helper: route_helper, ability_helper: ability_helper)
  end

  def as_json
    to_h
  end

  def to_json
    JSON.pretty_generate(as_json)
  end
end