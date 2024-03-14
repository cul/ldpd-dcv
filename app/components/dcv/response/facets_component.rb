# frozen_string_literal: true

module Dcv::Response
  class FacetsComponent < Blacklight::Component
    def initialize(blacklight_config:, hide_heading: false, response:, **opts)
      super
      @blacklight_config = blacklight_config
      @hide_heading = hide_heading
      @response = response
    end

    def facet_group_names
      @blacklight_config&.facet_group_names || []
    end
  end
end
