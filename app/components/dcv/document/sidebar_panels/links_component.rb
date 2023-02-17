# frozen_string_literal: true

module Dcv::Document::SidebarPanels
  class LinksComponent < ViewComponent::Base
    delegate :can_download?, :has_persistent_link?, :persistent_link_to, to: :helpers

    def initialize(document:, child_document: nil, configured_links: nil)
      @document = document
      @child_document = child_document || document
      @configured_links = configured_links || []
    end

    def display_related_urls
      helpers.display_related_urls(document: @document)
    end
  end
end