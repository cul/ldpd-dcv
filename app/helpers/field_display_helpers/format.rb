module FieldDisplayHelpers::Format
  DC_DOCUMENT_TYPES = ['PageDescription', 'Text'].freeze
  DC_IMAGE_TYPES = ['Image', 'StillImage'].freeze

  FORMAT_TRANSFORMED = {
    'resource' => 'File Asset', 'multipartitem' => 'Item', 'collection' => 'Collection'
  }.freeze

  def format_value_transformer(value)
    FORMAT_TRANSFORMED.fetch(value, value)
  end

  def is_image_document?(solr_doc, field = :dc_type_ssm)
    (DC_IMAGE_TYPES & Array(solr_doc[field])).present?
  end

  def is_text_document?(solr_doc, field = :dc_type_ssm)
    (DC_DOCUMENT_TYPES & Array(solr_doc[field])).present?
  end

  def mime_type_field_value(args={})
    dc_format = args[:document][args[:field]]
    object_profile = JSON.load(args[:document]['object_profile_ssm'].first.to_s) || {}
    ds_profile = object_profile.dig('datastreams', 'content') || {}
    ds_mime = ds_profile['dsMIME']
    values = Array(dc_format) + [ds_mime]
    values.uniq! && values.compact!
    values.delete_if { |x| values.length > 1 && x == 'application/octet-stream' }
    values.first
  end
end
