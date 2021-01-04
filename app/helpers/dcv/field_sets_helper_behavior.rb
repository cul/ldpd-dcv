module Dcv::FieldSetsHelperBehavior
  # duplicate Blacklight show_field behaviors for locally defined fieldsets 
  # modeled after Blacklight::ConfigurationHelperBehavior#document_show_fields
  def document_citation_fields(document = nil)
    blacklight_config.citation_fields
  end

  # modeled after Blacklight::BlacklightHelperBehavior#should_render_show_field?
  def should_render_citation_field?(document, field_config)
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
  end

  # modeled after Blacklight::BlacklightHelperBehavior#render_document_show_field_label
  def render_document_citation_field_label *args
    options = args.extract_options!
    document = args.first

    field = options[:field]

    html_escape t(:"blacklight.search.citation.label", label: document_citation_field_label(document, field))
  end

  # modeled after Blacklight::ConfigurationHelperBehavior#document_show_field_label
  def document_citation_field_label document, field
    field_config = document_citation_fields(document)[field]

    field_label(
      :"blacklight.search.fields.show.#{field}",
      :"blacklight.search.fields.#{field}",
      (field_config.label if field_config),
      field.to_s.humanize
    )
  end

  # modeled after Blacklight::BlacklightHelperBehavior#render_document_show_field_value
  def render_document_citation_field_value *args
    options = args.extract_options!
    document = args.shift || options[:document]

    field = args.shift || options[:field]
    presenter(document).render_document_citation_field_value field, options.except(:document, :field)
  end

  # modeled after Blacklight::ConfigurationHelperBehavior#render_document_show_field
  def document_geo_fields(document = nil)
    blacklight_config.geo_fields
  end

  # modeled after Blacklight::BlacklightHelperBehavior#should_render_show_field?
  def should_render_geo_field?(document, field_config)
    should_render_field?(field_config, document) && document_has_value?(document, field_config)
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