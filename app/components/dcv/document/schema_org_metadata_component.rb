# frozen_string_literal: true

module Dcv::Document
  # default partial to display solr document fields in catalog index view
  class SchemaOrgMetadataComponent < ViewComponent::Base
    renders_many :itemprops, "ItemPropComponent"

    def initialize(document:, **_opts)
      super
      @document = document
    end

    def before_render
      with_itemprop(itemprop: 'description', document: @document, field_name: 'abstract_ssm', value_index: 0)
      with_itemprop(itemprop: 'dateCreated', document: @document, field_name: 'origin_info_date_created_start_ssm', value_index: 0)
      with_itemprop(itemprop: 'keywords', document: @document, field_name: 'lib_all_subjects_ssm', value_index: false)
      with_itemprop(itemprop: 'genre', document: @document, field_name: 'lib_format_ssm', value_index: false)
      with_itemprop(itemprop: 'creator', document: @document, field_name: 'lib_name_ssm', value_index: false)
    end

    class ItemPropComponent < ViewComponent::Base
      def initialize(itemprop:, document:, field_name:, value_index:)
        @itemprop = itemprop
        @document = document
        @field_name = field_name
        @value_index = value_index
      end

      def field_value
        values = Array(@document[@field_name])
        CGI::escapeHTML(@value_index ? values[@value_index] : values.join(' ;'))
      end

      def render?
        @document[@field_name].present?
      end

      def call
        "<meta itemprop=\"#{@itemprop}\" content=\"#{field_value}\">".html_safe
      end
    end
  end
end