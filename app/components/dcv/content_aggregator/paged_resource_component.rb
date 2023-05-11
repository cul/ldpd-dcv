# frozen_string_literal: true

module Dcv::ContentAggregator
  class PagedResourceComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :get_resolved_asset_url, :get_manifest_url, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def render?
      @document['iiif_behavior_ssim']&.include?("paged")
    end

    def iiif_manifest
      get_manifest_url(@document)
    end
  end
end
