# frozen_string_literal: true

module Dcv
  class FacetItemComponent < Blacklight::FacetItemComponent
    include Dcv::Components::FacetItemBehavior

    delegate :facet_config, to: :@facet_item
  end
end