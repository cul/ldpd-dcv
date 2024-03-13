# frozen_string_literal: true

module Dcv::Response
  class CollapsiblePaginationComponent < Blacklight::Response::PaginationComponent
    def render?
      @response && helpers.show_pagination? and @response.total_pages > 1
    end
  end
end
