# frozen_string_literal: true

module Dcv::SearchContext
  class PaginationComponent < Blacklight::SearchContextComponent
    def will_render?(**_args)
      render?
    end

    def render?
      ([:prev, :next] & @search_context.keys).present? if @search_context
    end
  end
end
