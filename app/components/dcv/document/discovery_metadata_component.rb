# frozen_string_literal: true

module Dcv::Document
  class DiscoveryMetadataComponent < ViewComponent::Base
    attr_reader :application_name, :id_url

    renders_one :opengraph, Dcv::Document::DiscoveryMetadata::OpengraphComponent
    renders_one :open_url, Dcv::Document::DiscoveryMetadata::OpenUrlComponent
    renders_one :schema_org, Dcv::Document::SchemaOrgMetadataComponent

    def initialize(document_presenter:, application_name:, id_url:)
      @document_presenter = document_presenter
      @id_url = id_url
      @application_name = application_name
    end

    def before_render
      component_args = { document: @document_presenter.document, document_presenter: @document_presenter, id_url: @id_url, application_name: @application_name }
      with_schema_org(**component_args)
      with_opengraph(**component_args)
      with_open_url(**component_args)
    end

    def call
      safe_join(
        [schema_org, opengraph, open_url]
      )
    end
  end
end
