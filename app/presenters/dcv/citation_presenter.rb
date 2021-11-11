# frozen_string_literal: true
module Dcv
  class CitationPresenter < Dcv::ShowPresenter
    def display_type(base_name = nil, default: nil)
      if ['ContentAggregator', 'Collection', 'GenericResource'].include?(document['active_fedora_model_ssi'])
        return document['active_fedora_model_ssi'].underscore
      end
      'default'
    end

    def render_document_citation_field_value field, options = {}
      field_config = @configuration.citation_fields[field] || Blacklight::Configuration::NullField.new
      value = options[:value] || field_value(field_config, options)

      field_values(field_config, value: Array(value))
    end

    private

    # @return [Hash<String,Configuration::Field>]
    def fields
      configuration.citation_fields
    end

    def view_config
      configuration.view_config(:citation)
    end

    def field_config(field)
      configuration.citation_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end