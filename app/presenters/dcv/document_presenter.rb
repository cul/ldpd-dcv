module Dcv
  class DocumentPresenter < Blacklight::DocumentPresenter
    def render_document_citation_field_value field, options = {}
      field_config = @configuration.citation_fields[field]
      value = options[:value] || get_field_values(field, field_config, options)

      render_field_value value, field_config
    end

    def render_document_geo_field_value field, options = {}
      field_config = @configuration.geo_fields[field]
      value = options[:value] || get_field_values(field, field_config, options)

      render_field_value value, field_config
    end

    def render_document_dynamic_field_value field, options = {}
      field_config = options[:field_config]
      value = options[:value] || get_field_values(field, field_config, options)

      render_field_value value, field_config
    end
  end
end