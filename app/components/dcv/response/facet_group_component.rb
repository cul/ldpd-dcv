# frozen_string_literal: true

module Dcv::Response
  class FacetGroupComponent < Blacklight::Response::FacetGroupComponent
    def initialize(hide_heading: false, **opts)
      super(**opts)
      @hide_heading = hide_heading
    end

    def render_facet_partials(options = {})
      facets_from_request = @fields.map { |facet_field| @response.aggregations[facet_field] }.compact
      safe_join(facets_from_request.map do |display_facet|
        field_config = helpers.blacklight_config.facet_configuration_for_field(display_facet.name)
        render(Blacklight::FacetComponent.new(
          display_facet: display_facet,
          field_config: field_config,
          response: @response,
          component: Dcv::FacetFieldListComponent,
          layout: (params[:action] == 'facet' ? false : options[:layout])
        ))
      end.compact, "\n")
    end
  end
end
