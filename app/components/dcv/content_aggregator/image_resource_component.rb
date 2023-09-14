# frozen_string_literal: true

module Dcv::ContentAggregator
  class ImageResourceComponent < ViewComponent::Base
    DC_TYPE = 'StillImage'.freeze

    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :get_resolved_asset_url, :get_manifest_url, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def render?
      return true if Array(@document.fetch(:dc_type_sim)).include?('StillImage')
      Array(@document.fetch(:dc_type_sim)).include?('InteractiveResource') || helpers.structured_children_not_type(dc_type: DC_TYPE).blank?
    end

    def iiif_manifest
      get_manifest_url(@document)
    end
  end
end
