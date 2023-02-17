# frozen_string_literal: true

module Dcv::Document::SidebarPanels
  class LocationDataComponent < ViewComponent::Base
    delegate :local_facet_search_url, to: :helpers

    def initialize(document:)
      @document = document
    end

    def before_render
      @geo_presenter = helpers.geo_presenter(@document)
    end
  end
end