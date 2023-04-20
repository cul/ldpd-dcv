# frozen_string_literal: true

module Dcv
  class FacetFieldListComponent < Blacklight::FacetFieldListComponent
    delegate :search_state, to: :helpers
    def render?
      super && (@facet_field.paginator.items.length > 1 || facet_item_presenter(@facet_field.paginator.items.first).selected?)
    end
    def facet_item_presenter(facet_item)
      facet_config = @facet_field.facet_field
      (facet_config.item_presenter || Blacklight::FacetItemPresenter).new(facet_item, facet_config, self, @facet_field)
    end
  end
end