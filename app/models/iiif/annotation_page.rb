class Iiif::AnnotationPage
  attr_reader :id, :canvas, :route_helper
  def initialize(canvas, route_helper)
    @canvas = canvas
    @route_helper = route_helper 
  end

  def painting_annotation
    @painting_annotation ||= Iiif::PaintingAnnotation.new(canvas, route_helper)
  end

  def uri
    @uri ||= route_helper.iiif_annotation_page_url(canvas.routing_opts)
  end

  def to_h
    as_json
  end

  def as_json
    {
      type: "AnnotationPage",
      id: uri,
      items: [
        painting_annotation.to_h
      ]
    }
  end

  def to_json
    JSON.pretty_generate(as_json)
  end
end