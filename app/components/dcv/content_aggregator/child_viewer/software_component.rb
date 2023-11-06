# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer
  class SoftwareComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :poster_url, :get_resolved_asset_url, to: :helpers

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
