# frozen_string_literal: true

module Dcv::Response
  class CollapsiblePaginationComponent < Blacklight::Response::PaginationComponent
    def will_render?(controller:, helpers:)
      return false unless controller.has_search_parameters?
      @response && helpers.show_pagination? and @response.total_pages > 0
    end

    def render?
      will_render?(controller: controller, helpers: helpers)
    end

    def paginator_class
      return OnlyPagePaginator if (@response && @response.total_pages < 2)
      Kaminari::Helpers::Paginator
    end

    class OnlyPagePaginator < Kaminari::Helpers::Paginator
      def first?
        true
      end

      def current?
        true
      end

      def last?
        true
      end

      def partial_path
        "#{@views_prefix}/kaminari/#{@theme}/paginator".gsub('//', '/')
      end

      # this is an override to render unconditionally, cf Kaminari::Helpers::Paginator#render
      def render(&block)
        instance_eval(&block)
        @output_buffer.presence
      end
    end
  end
end
