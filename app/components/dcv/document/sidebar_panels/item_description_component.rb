# frozen_string_literal: true

module Dcv::Document::SidebarPanels
  class ItemDescriptionComponent < ViewComponent::Base
    delegate :site_edit_link, :terms_of_use_url, to: :helpers
    def initialize(document:, citation_presenter: nil, document_presenter: nil, alignment: 'vertical', link_helpers: [])
      @document = document
      @citation_presenter = citation_presenter
      @document_presenter = document_presenter
      @alignment = alignment
      @link_helpers = link_helpers
    end
    def before_render
      @citation_presenter ||= helpers.citation_presenter(@document)
      @document_presenter ||= helpers.document_presenter(@document)
    end
  end
end