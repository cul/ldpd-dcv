# frozen_string_literal: true

module Dcv::SearchContext
  class PaginationComponent < Blacklight::SearchContextComponent
    def will_render?(**_args)
      render?
    end
  end
end
