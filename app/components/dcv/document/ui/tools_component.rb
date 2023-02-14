# frozen_string_literal: true

module Dcv::Document::Ui
  class ToolsComponent < ViewComponent::Base
    include Dcv::Components::StructuredChildrenBehavior

    delegate :has_non_public_children?, to: :helpers
    renders_one :mods_widget, Dcv::Document::Ui::ModsModalDisplayComponent
    renders_one :iiif_widget, Dcv::Document::Ui::IiifManifestComponent
    renders_one :citation_widget, Dcv::Document::Ui::CitationsComponent

    def initialize(document:, **opts)
      super
      @document = document
    end

    def before_render
      return unless active_fedora_model.present?
      with_mods_widget(document: @document)
      with_iiif_widget(document: @document)
      with_citation_widget(document: @document)
    end

    def local_downloads
      case active_fedora_model
      when 'ContentAggregator'
        (structured_children.length > 0 && !has_non_public_children?(children: structured_children))
      else
        false
      end
    end

    def widgets?
      mods_widget? || iiif_widget? || citation_widget?
    end

    private

    def active_fedora_model
      @document[:active_fedora_model_ssi]
    end
  end
end