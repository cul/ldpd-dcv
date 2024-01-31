# frozen_string_literal: true

module Dcv
  class FacetItemComponent < Blacklight::FacetItemComponent
    include Dcv::Components::FacetItemBehavior

    delegate :facet_config, to: :@facet_item

    # it should not hold a strong reference to the view_context, which refers to the controller
    # @private
    # @deprecated
    def with_view_context(view_context)
      @view_context = WeakRef.new(view_context)
      self
    end
 end
end