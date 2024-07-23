# frozen_string_literal: true

module Dcv::ContentAggregator
  class LocalResourceComponent < BaseMiradorComponent
    delegate :can_access_asset?, :get_resolved_asset_url, :get_manifest_url, to: :helpers

    def initialize(document:, **opts)
      super
      @num_children = opts[:num_children] || document[:cul_number_of_members_isi]
    end

    def render?
      return true if (Array(@document.fetch(:active_fedora_model_ssi)) & ['ContentAggregator', 'GenericResource']).present?
    end
  end
end
