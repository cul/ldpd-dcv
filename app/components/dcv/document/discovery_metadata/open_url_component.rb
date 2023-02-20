# frozen_string_literal: true

module Dcv::Document::DiscoveryMetadata
  class OpenUrlComponent < ViewComponent::Base
    attr_reader :application_name, :request

    def initialize(document_presenter:, id_url:, application_name:, **_opts)
      @document = document_presenter.document
      @id_url = id_url
      @application_name = application_name
    end

    def render?
      @document.respond_to?(:export_as_openurl_ctx_kev)
    end

    def call
      open_url_data = @document.export_as_openurl_ctx_kev(id_url: @id_url, application_name: @application_name)
      "<span class=\"Z3988\" title=\"#{open_url_data}\"></span>".html_safe
    end
  end
end
