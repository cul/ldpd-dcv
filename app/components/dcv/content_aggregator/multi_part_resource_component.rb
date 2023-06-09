# frozen_string_literal: true

module Dcv::ContentAggregator
  class MultiPartResourceComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :archive_org_id_for_document, :get_manifest_url, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def render?
      archive_org_id_for_document(@document)
    end

    def iiif_manifest
      get_manifest_url(@document, collection: true)
    end
  end
end
