# frozen_string_literal: true

module Dcv::ContentAggregator::Carousel
  class EmptyComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :can_access_asset?, :current_user, :get_resolved_asset_url, :has_synchronized_media?, to: :helpers

    def initialize(document:, local_downloads:, structured_children: nil, parent_title: nil, **_opts)
      super
      @document = document
      @local_downloads = local_downloads
      @structured_children = structured_children
      @parent_title = parent_title
    end

    def has_embargoed_children?
      helpers.has_embargoed_children?(document: @document, children: structured_children)
    end

    def has_unviewable_children?
      helpers.has_unviewable_children?(document: @document, children: structured_children)
    end

    def child_title_for(child)
      @document['title_display_ssm'].present? && child[:title] == @document['title_display_ssm'].first ? '&nbsp;'.html_safe : child[:title]
    end
  end
end
