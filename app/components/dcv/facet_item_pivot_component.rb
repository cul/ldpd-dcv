# frozen_string_literal: true

module Dcv
  class FacetItemPivotComponent < Blacklight::FacetItemPivotComponent
    include Dcv::Components::FacetItemBehavior

    delegate :facet_config, to: :@facet_item

    # This is copied from Blacklight::FacetItemComponent because it is missing
    # on FacetItemPivotComponent in Blacklight v7.33.1
    # This is a little shim to let us call the render methods below outside the
    # usual component rendering cycle (for backward compatibility)
    # @private
    # @deprecated
    def with_view_context(view_context)
      @view_context = view_context
      self
    end
  end
end