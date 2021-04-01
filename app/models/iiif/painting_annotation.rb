class Iiif::PaintingAnnotation
  include Dcv::AccessLevels
  attr_reader :id, :canvas, :route_helper

  def initialize(canvas, route_helper)
    @canvas = canvas
    @route_helper = route_helper 
  end
  def to_h
    painting_annotation = IIIF_TEMPLATES['painting_annotation'].deep_dup
    routing_opts = canvas.routing_opts.merge(id: 'painting')
    painting_annotation['id'] = route_helper.iiif_annotation_url(routing_opts)
    underscore = "#{routing_opts[:registrant]}.#{routing_opts[:doi]}"
    underscore.sub!(/[^A-Za-z0-9]/,'_')
    body = { 'type' => canvas.canvas_type }
    if body['type'] == Iiif::Type::V3::IMAGE
      dimensions = canvas.dimensions.select {|k,h| k == :height or k == :width}.to_h.stringify_keys
      body.merge!(IIIF_TEMPLATES['image_annotation_body'].deep_dup)
      body.merge!(dimensions)
      body['service'].merge!(dimensions)
      body['id'] = route_helper.iiif_annotation_url(routing_opts.merge(format: 'jpg'))
      iiif_id = Dcv::Utils::CdnUtils.info_url(id: canvas.fedora_pid).sub(/\/info.json$/,'')
      body['service']['id'] = iiif_id
    elsif body['type'] == Iiif::Type::V3::TEXT
      body.merge!(IIIF_TEMPLATES['text_annotation_body'].deep_dup)
      catalog_id = canvas.solr_document.id
      bytestream_id = Dcv::Utils::UrlUtils.preferred_content_bytestream(canvas.solr_document)
      body['id'] = route_helper.bytestream_content_url({catalog_id: catalog_id, filename: 'content.pdf', bytestream_id: bytestream_id, download: false})
      painting_annotation['body'] = body
    elsif body['type'] == Iiif::Type::V3::VIDEO
      # TODO: media streaming with auth service
      body['id'] = Dcv::Utils::CdnUtils.wowza_media_token_url(canvas.solr_document, self, route_helper.request.remote_ip)
      body['format'] = 'application/vnd.apple.mpegurl'
    elsif body['type'] == Iiif::Type::V3::SOUND
      # TODO: media streaming with auth service
      body['id'] = Dcv::Utils::CdnUtils.wowza_media_token_url(canvas.solr_document, self, route_helper.request.remote_ip)
      body['format'] = 'application/vnd.apple.mpegurl'
    else
      catalog_id = canvas.solr_document.id
      filename = canvas.solr_document['label_ssi']
      body['id'] = route_helper.bytestream_content_url({catalog_id: catalog_id, filename: filename, bytestream_id: 'content', download: true})
    end
    # TODO: supplementing for captions where available
    # TODO: rendering for original download where available
    painting_annotation['body'] = body
    painting_annotation['target'] = canvas.id
    painting_annotation
  end

  def as_json
    to_h
  end

  def to_json
    JSON.pretty_generate(as_json)
  end
end