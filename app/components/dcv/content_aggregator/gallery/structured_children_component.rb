# frozen_string_literal: true

module Dcv::ContentAggregator::Gallery
  class StructuredChildrenComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :get_resolved_asset_url, :has_synchronized_media?, to: :helpers

    def initialize(document:, structured_children: nil, **_opts)
      super
      @document = document
      @structured_children = structured_children
    end

    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end
  end
end
