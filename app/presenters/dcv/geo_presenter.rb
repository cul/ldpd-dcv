# frozen_string_literal: true
module Dcv
  class GeoPresenter < Dcv::ShowPresenter
    def display_type(base_name = nil, default: nil)
      if ['ContentAggregator', 'Collection', 'GenericResource'].include?(document['active_fedora_model_ssi'])
        return document['active_fedora_model_ssi'].underscore
      end
      'default'
    end

    def render_document_geo_field_value field, options = {}
      field_config = @configuration.geo_fields[field] || Blacklight::Configuration::NullField.new
      value = options[:value] || field_value(field_config, options)

      field_values(field_config, value: Array(value))
    end

    private

    # @return [Hash<String,Configuration::Field>]
    def fields
      configuration.geo_fields
    end

    def view_config
      configuration.view_config(:geo).inspect
    end

    def field_config(field)
      configuration.geo_fields.fetch(field) { Configuration::NullField.new(field) }
    end
  end
end