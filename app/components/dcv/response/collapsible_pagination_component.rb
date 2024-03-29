# frozen_string_literal: true

module Dcv::Response
  class CollapsiblePaginationComponent < Blacklight::Response::PaginationComponent
    def will_render?(controller:, helpers:)
      return false unless controller.has_search_parameters?
      @response && helpers.show_pagination? and @response.total_pages > 1
    end

    def render?
      will_render?(controller: controller, helpers: helpers)
    end
  end
end
