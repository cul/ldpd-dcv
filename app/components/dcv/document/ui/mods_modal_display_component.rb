# frozen_string_literal: true

module Dcv::Document::Ui
  class ModsModalDisplayComponent < ViewComponent::Base
    include Dcv::Components::ActiveFedoraDocumentBehavior

    delegate :item_mods_path, to: :helpers

    def initialize(document:, **opts)
      super
      @document = document
    end

    def render?
      has_datastream?('descMetadata')
    end

    def call
      content_tag(:button,
        data: {
          'display-url' => item_mods_path(id: @document.id, type: 'formatted_text'),
          'download-url' => item_mods_path(id: @document.id, type: 'download'),
          'modal-title-func' => 'downloadXmlTitle',
          'modal-size' => 'xl',
          toggle: 'modal', target: '#dcvModal'
        },
        aria: { label: 'Display XML Metadata' },
        class: 'btn btn-outline-secondary btn-sm') do
        content_tag :i, '', class: "fa fa-file-code-o", data: { toggle: 'tooltip' }, title: 'Display XML Metadata'
      end
    end
  end
end