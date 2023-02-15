# frozen_string_literal: true

module Dcv::Document::Fields
  # Until Blacklight::MetadataFieldLayoutComponent permits setting the content tag
  # we must mimic the interface instead of using it or subclassing
  class ListItemFieldLayoutComponent < Blacklight::Component
    include Blacklight::ContentAreasShim

    with_collection_parameter :field
    renders_one :label
    renders_many :values, (lambda do |value: nil, &block|
      if block
        content_tag :span, class: "blacklight-#{@key}", &block
      else
        value = value.join(", ") if value.is_a? Array
        content_tag :span, value, class: "#blacklight-#{@key}"
      end
    end)

    # @param field [Blacklight::FieldPresenter]
    def initialize(field:, label_class: nil, value_class: nil)
      @field = field
      @key = @field.key.parameterize
      @label_class = label_class
      @value_class = value_class
    end
  end
end