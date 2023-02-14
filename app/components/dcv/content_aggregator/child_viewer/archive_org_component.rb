# frozen_string_literal: true

module Dcv::ContentAggregator::ChildViewer
  class ArchiveOrgComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::ArchiveOrgBehavior

    delegate :poster_url, to: :helpers

    def initialize(document:, child:, child_index:,**_opts)
      super
      @document = document
      @child = child
      @child_index = child_index
    end

    def child_title
      @child[:title].present? ? @child[:title].strip : ''
    end
  end
end
