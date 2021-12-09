module Dcv::FieldSetsHelperBehavior
  # duplicate Blacklight show_field behaviors for locally defined fieldsets 
  # modeled after Blacklight::ConfigurationHelperBehavior#document_show_fields
  def document_citation_fields(document = nil)
    blacklight_config.citation_fields
  end

  # modeled after Blacklight::ConfigurationHelperBehavior#render_document_show_field
  def document_geo_fields(document = nil)
    blacklight_config.geo_fields
  end

  def document_tombstone_fields(document = nil)
    blacklight_config.index_fields.select do |field, field_config|
      field_config[:tombstone_display] && document[field].present?
    end.to_h
  end

  def render_document_tombstone_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    content_tag(:div, Array(document[field]).first, class: "ellipsis")
  end
end