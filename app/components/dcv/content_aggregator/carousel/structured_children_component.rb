# frozen_string_literal: true

module Dcv::ContentAggregator::Carousel
  class StructuredChildrenComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior
    include Dcv::Components::ChildViewerBehavior

    delegate :can_access_asset?, :current_user, :get_resolved_asset_url, :has_synchronized_media?, to: :helpers

    renders_one :gallery, -> (document:, structured_children:) do
      case active_fedora_model
      when 'ContentAggregator'
        Dcv::ContentAggregator::Gallery::StructuredChildrenComponent.new(document: document, structured_children: structured_children)
      when 'Collection'
        Dcv::Collection::GalleryComponent.new(document: document, structured_children: structured_children)
      end
    end

    def initialize(document:, local_downloads:, structured_children: nil, parent_title: nil, **_opts)
      super
      @document = document
      @local_downloads = local_downloads
      @structured_children = structured_children
      @parent_title = parent_title
    end

    def before_render
      with_gallery(document: @document, structured_children: @structured_children)
    end

    def hide_controls?
      structured_children.length < 2
    end
  end
end
