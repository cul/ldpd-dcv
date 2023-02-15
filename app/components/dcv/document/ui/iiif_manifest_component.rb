# frozen_string_literal: true

module Dcv::Document::Ui
  class IiifManifestComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior
    include Dcv::Components::StructuredChildrenBehavior

    delegate :get_manifest_url, :has_public_children?,
             :has_non_public_children?, :inline_svg, :item_mods_path, to: :helpers

    def initialize(document:, **opts)
      super
      @document = document
    end

    def render?
      case active_fedora_model
      when 'Collection'
        render_collection?
      when 'ContentAggregator'
        render_content_aggregator?
      when 'GenericResource'
        render_generic_resource?
      else
        false
      end
    end

    def call
      content_tag(:a,
        id: "draggable-iiif-button",
        href: get_manifest_url(@document),
        class: "btn btn-outline-secondary btn-sm grabbable localicon-iiif",
        data: { toggle: 'tooltip' },
        aria: { label: 'drag-n-drop iiif manifest' }) do
        content_tag :span, inline_svg('iiif-logo.svg'), data: { toggle: 'tooltip' }, title: 'drag-n-drop iiif manifest'
      end
    end

    private

    def render_collection?
      @document.has_persistent_url?
    end

    def render_content_aggregator?
        public_ability = Ability.new
        @document.has_persistent_url? &&
        has_public_children?(children: structured_children, ability: public_ability) &&
        !has_non_public_children?(children: structured_children, ability: public_ability) &&
        structured_children.detect {|x| x[:dc_type] =~ /image/i }
    end

    def render_generic_resource?
      @document['dc_type_ssm'].present? && @document['dc_type_ssm'].first.eql?('StillImage')
    end
  end
end