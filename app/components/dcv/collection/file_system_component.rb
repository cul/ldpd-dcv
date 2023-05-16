# frozen_string_literal: true

module Dcv::Collection
  class FileSystemComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :get_manifest_url, :get_resolved_asset_url, :is_file_system?, :resolve_catalog_bytestreams_path, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end

    def iiif_manifest
      get_manifest_url(@document, collection: true)
    end

    def render?
      is_file_system?(@document) && iiif_manifest
    end
  end
end
