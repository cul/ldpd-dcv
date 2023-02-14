# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer
  class ImageComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :is_image_document?, :is_text_document?, :poster_url, to: :helpers

    def initialize(document:, child:, child_index:, local_downloads: false, **_opts)
      super
      @document = document
      @child = child
      @child_index = child_index
      @local_downloads = local_downloads
    end

    def child_title
      @child[:title].present? ? @child[:title].strip : ''
    end
  end
end
