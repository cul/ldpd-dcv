module Dcv::Resources::RelsIntBehavior
  INTERNAL_DSIDS = ['AUDIT','DC','RELS-INT','RELS-EXT'].freeze
  METADATA_DSIDS = ['descMetadata','rightsMetadata'].freeze
  def resources_for_document(document=@document)
    model = document['active_fedora_model_ssi']
    profile = document['object_profile_ssm'].first
    profile = profile ? JSON.load(profile) : {}
    ds_profiles = profile["datastreams"]

    results = Hash.new { |hash, key| hash[key] =  {} }

    if model == 'GenericResource'
      # pull the basic metadata from the Fedora info
      ds_profiles.each do |dsid,ds_props|
        next unless is_resource_datastream(dsid)
        mime_type = ds_props['dsMIME'] if ds_props
        next if mime_type =~ /jp2$/
        label = ds_props["dsLabel"].split('/').last
        results[dsid].merge!( {
          id: dsid, title: label,
          mime_type: ds_props["dsMIME"],
          url: url_for_content("info:fedora/#{document[:id]}/#{dsid}", label, ds_props["dsMIME"])
        })
      end
      # override the basic metadata if RELS-INT was indexed
      streams = document['rels_int_profile_tesim'] ?
        JSON.load(document['rels_int_profile_tesim'][0]) :
        {}
      streams.each do |k,v|
        dsid = k.to_s.split('/').last
        next unless results.has_key? dsid
        next if k =~ /content$/
        ds_props = ds_profiles[dsid]
        mime_type = ds_props['dsMIME'] if ds_props
        mime_type ||= v['format'].first
        next if mime_type =~ /jp2$/
        title = k.split('/')[-1]
        width = (v['exif_image_width'] || v['image_width'] ||[ ]).first.to_i
        length = (v['exif_image_length'] || v['image_length'] || []).first.to_i
        size = (v['extent'] || []).first.to_i
        results[dsid].merge!({
          id: dsid, title: title, mime_type: mime_type, length: length,
          width: width, size: size
        })
      end
      # remove the content link for image files; no TIFF resources
      if document['dc_type_ssm'].present? && document['dc_type_ssm'].include?('StillImage')
        results.delete('content')
      end
    end
    return results.map { |k,v| v }
  end

  def is_resource_datastream(id)
    dsid = id.to_s.split('/').last
    (dsid.present? and !INTERNAL_DSIDS.include?(dsid) and !METADATA_DSIDS.include?(dsid))
  end

  def url_for_content(key, dsLabel, mime)
    parts = key.split('/')

    # Get extension from dsLabel if possible
    ext = (dsLabel =~ /\.[A-Za-z0-9]+$/) ? File.extname(dsLabel)[1..-1] : nil

    # If we can infer a label from the mime type, use that instead
    if mime.present?
      mime_type_object = MIME::Types[mime].first
      if mime_type_object.present?
        possible_extensions = mime_type_object.extensions
        # If there is only one extension possibility for this mime type,
        # OR if there are multiple possibilities and none of them match
        # the mime type we got from the dsLabel, choose the first extension
        ext = possible_extensions.first if possible_extensions.length == 1 || ! possible_extensions.include?(ext)
      end
    end

    # Fall back to bin extension if we cannot determine the mime type
    ext = 'bin' if ext.nil?

    bytestream_content_url(catalog_id: parts[1], bytestream_id: parts[2], format: ext)
  end
end
