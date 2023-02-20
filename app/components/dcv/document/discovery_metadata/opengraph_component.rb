# frozen_string_literal: true

module Dcv::Document::DiscoveryMetadata
  class OpengraphComponent < ViewComponent::Base
    attr_reader :application_name, :request

    renders_many :properties, lambda { |property:, content:| tag :meta, property: property, content: content }

    def initialize(document_presenter:, id_url:, application_name:, **_opts)
      @document_presenter = document_presenter
      @id_url = id_url
      @application_name = application_name
    end

    def before_render
      with_property(property: "og:title", content: @document_presenter.html_title)
      with_property(property: "og:type", content: 'image') #this is wrong, but what the app has done previously
      with_property(property: "og:url", content: @id_url)
      desc = @document_presenter.document['abstract_ssm'][0] if @document_presenter.document['abstract_ssm']
      with_property(property: "og:description", content: desc) if desc
      with_property(property: "og:site_name", content: @application_name)
    end

    def call
      safe_join(properties)
    end
  end
end
