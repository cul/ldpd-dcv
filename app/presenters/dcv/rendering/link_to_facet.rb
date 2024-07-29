module Dcv
  module Rendering
    class LinkToFacet < Blacklight::Rendering::LinkToFacet
      def render
        return next_step(values) unless linkable_facet

        next_step(render_link)
      end

      def linkable_facet
        config.link_to_facet && context.blacklight_config.facet_fields[link_field]
      end
    end
  end
end