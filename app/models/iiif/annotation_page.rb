class Iiif::AnnotationPage
  attr_reader :id, :canvas, :route_helper, :ability_helper
  def initialize(canvas, route_helper:, ability_helper:, **args)
    @canvas = canvas
    @route_helper = route_helper
    @id = route_helper.iiif_annotation_page_url(canvas.routing_opts)
    @ability_helper = ability_helper
  end

  def painting_annotation
    if ability_helper.can?(Ability::ACCESS_ASSET, canvas.solr_document)
      @painting_annotation ||= Iiif::PaintingAnnotation.new(canvas, route_helper: route_helper, ability_helper: ability_helper)
    else
      @painting_annotation ||= Iiif::ProbeAnnotation.new(canvas, route_helper: route_helper, ability_helper: ability_helper)
    end
  end

  #TODO: Can this be removed?
  def uri
    @uri ||= @id
  end

  def to_h
    as_json
  end

  def as_json
    {
      type: "AnnotationPage",
      id: id,
      items: [
        painting_annotation.to_h
      ]
    }
  end

  def to_json
    JSON.pretty_generate(as_json)
  end
end