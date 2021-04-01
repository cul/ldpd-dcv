class Iiif::Canvas < Iiif::BaseResource
  attr_reader :id, :manifest_routing_opts, :route_helper, :doi
  attr_accessor :image, :label

  def initialize(id, solr_document, route_helper, manifest_routing_opts, label=nil)
    super(id, solr_document)
    @manifest_routing_opts = manifest_routing_opts
    @label = label || solr_document['title_display_ssm'].first
    @doi = solr_document.doi_identifier
    @route_helper = route_helper
  end

  def routing_opts
    registrant, doi = self.doi.split('/')
    @manifest_routing_opts.merge(registrant: registrant, doi: doi)
  end

  def canvas_type
    Iiif::Type::V3.for(Array(@solr_document['dc_type_ssm']).first)
  end

  def as_json(opts = {})
    canvas = IIIF_TEMPLATES['canvas'].deep_dup
    canvas["@context"] = "http://iiif.io/api/presentation/3/context.json" if opts[:include]&.include?(:context)
    canvas['id'] = id
    canvas['type'] = 'Canvas'
    canvas['label'] = label.to_s
    canvas['thumbnail'] = thumbnail
    if canvas_type == Iiif::Type::V3::IMAGE
      canvas['height'] = dimensions[:height]
      canvas['width'] = dimensions[:width]
    else
      # TODO: video dimensions; audio and document dims irrelevant/defaulted to 1
      canvas['height'] = 1
      canvas['width'] = 1
    end
    canvas['items'] = [annotation_page.to_h]
    canvas
  end

  def dimensions
    @dimensions ||= begin
      json_props = JSON.parse(@solr_document[:rels_int_profile_tesim]&.join || '{}')
      content_key = json_props.keys.detect { |k| k.to_s.split('/')[-1] == 'content' }
      content_props = content_key ? json_props[content_key] : {}
      { width: Array(content_props['image_width']).first.to_i, height: Array(content_props['image_length']).first.to_i }
    end
    @dimensions
  end

  def annotation_page
    @annotation_page ||= Iiif::AnnotationPage.new(self, route_helper)
  end

  def thumbnail
    @thumbnail ||= begin
      iiif_id = Dcv::Utils::CdnUtils.info_url(id: @solr_document.id).sub(/\/info.json$/,'')

      _props = dimensions.dup
      if _props[:width] > _props[:height]
        _props[:height] = (_props[:height] * 256) / (_props[:width])
        _props[:width] = 256
      elsif _props[:height] > 0
        _props[:width] = (_props[:width] * 256) / (_props[:height])
        _props[:height] = 256
      end
      _props[:type] = 'Image'
      _props[:format] = 'image/jpeg'
      _props[:id] = Dcv::Utils::CdnUtils.asset_url(id: @solr_document.id, size: 256, type: 'featured', format: 'jpg')
      _props[:service] = [
        {
        "id": iiif_id,
        "type": "ImageService3",
        "profile": "level2"
        }
      ]
      _props.freeze
    end
  end
end