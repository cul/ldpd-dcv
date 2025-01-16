class Iiif::PaintingAnnotation
  include Dcv::AccessLevels
  attr_reader :id, :canvas, :route_helper, :ability_helper

  def initialize(canvas, route_helper:, ability_helper:)
    @canvas = canvas
    @route_helper = route_helper
    @ability_helper = ability_helper
  end

  def to_h
    painting_annotation = IIIF_TEMPLATES['painting_annotation'].deep_dup
    routing_opts = canvas.routing_opts.merge(id: 'painting')
    painting_annotation['id'] = route_helper.iiif_annotation_url(routing_opts)
    # TODO: supplementing for captions where available
    # TODO: rendering for original download where available
    painting_annotation['body'] = annotation_body(routing_opts)
    painting_annotation['target'] = canvas.id
    painting_annotation
  end

  def annotation_body(routing_opts)
    body = { 'type' => canvas.canvas_type }
    catalog_id = canvas.solr_document.id
    if body['type'] == Iiif::Type::V3::IMAGE
      dimensions = canvas.dimensions.select {|k,h| k == :height or k == :width}.to_h.stringify_keys
      body.merge!(IIIF_TEMPLATES['image_annotation_body'].deep_dup)
      body.merge!(dimensions)
      body['id'] = route_helper.iiif_annotation_url(routing_opts.merge(format: 'jpg'))
      body['format'] = 'image/jpeg'
      iiif_id = Dcv::Utils::CdnUtils.info_url(id: canvas.fedora_pid).sub(/\/info.json$/,'')
      body['service'].first['@id'] = iiif_id
      unless ability_helper.can_access_asset?(canvas.solr_document, Ability.new) # check if public
        body['service'].first['service'] = [Iiif::Authz::V2::ProbeService.new(canvas, route_helper: route_helper, ability_helper: ability_helper)]
      end
    elsif body['type'] == Iiif::Type::V3::TEXT
      body.merge!(IIIF_TEMPLATES['text_annotation_body'].deep_dup)
      bytestream_id = Dcv::Utils::UrlUtils.preferred_content_bytestream(canvas.solr_document)
      body['id'] = route_helper.bytestream_content_url({catalog_id: catalog_id, filename: 'content.pdf', bytestream_id: bytestream_id, download: false})
      body['service'] = [Iiif::Authz::V2::ProbeService.new(canvas, route_helper: route_helper, ability_helper: ability_helper)]
    elsif body['type'] == Iiif::Type::V3::VIDEO || body['type'] == Iiif::Type::V3::SOUND
      # use the video player for all AMI
      body['type'] = Iiif::Type::V3::VIDEO
      # media streaming with auth service
      bytestream_id = Dcv::Utils::UrlUtils.preferred_content_bytestream(canvas.solr_document)
      body['id'] = route_helper.bytestream_resource_url(catalog_id: catalog_id, bytestream_id: bytestream_id)
      body['service'] = [Iiif::Authz::V2::ProbeService.new(canvas, route_helper: route_helper, ability_helper: ability_helper)]
    else
      filename = canvas.solr_document['label_ssi']
      body['id'] = route_helper.bytestream_content_url({catalog_id: catalog_id, filename: filename, bytestream_id: 'content', download: true})
    end
    body
  end

  def as_json(opts = {})
    to_h
  end

  def to_json
    JSON.pretty_generate(as_json)
  end
end