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
end