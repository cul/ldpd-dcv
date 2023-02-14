# frozen_string_literal: true

module Dcv::Collection
  class GalleryComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :get_resolved_asset_url, :resolve_catalog_bytestreams_path, to: :helpers

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end
  end
end
