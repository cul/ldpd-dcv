# frozen_string_literal: true

module Dcv::Document::Ui
  class CitationsComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior

    def initialize(document:, **opts)
      super
      @document = document
    end

    def render?
      case active_fedora_model
      when 'Collection'
        true
      when 'ContentAggregator'
        true
      else
        false
      end
    end

    def item_citation_path(type:)
      helpers.item_citation_path(@document['id'], type: type)
    end
  end
end