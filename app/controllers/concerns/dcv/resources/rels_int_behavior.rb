module Dcv::Resources::RelsIntBehavior
  def resources_for_document(document=@document)
    model = document['active_fedora_model_ssi']
    profile = document['object_profile_ssm'].first
    profile = profile ? JSON.load(profile) : {}
    ds_profiles = profile["datastreams"]
    if model == 'GenericResource'
      streams = document['rels_int_profile_tesim'] ?
        JSON.load(document['rels_int_profile_tesim'][0]) :
        {}
      results = []
      streams.each do |k,v|
        next unless v["format_of"] and v["format_of"].first =~ /content$/
        title = k.split('/')[-1]
        id = k
        mime_type = v['format'].first
        next if mime_type =~ /jp2$/
        width = (v['exif_image_width'] || v['image_width'] ||[ ]).first.to_i
        length = (v['exif_image_length'] || v['image_length'] || []).first.to_i
        size = (v['extent'] || []).first.to_i
        url = url_for_content(id, mime_type)
        results << {
          id: id, title: title, mime_type: mime_type, length: length,
          width: width, size: size, url: url}
      end
      unless document['dc_type_ssm'].include? 'StillImage'
        if ds_profiles && ds_profiles["content"]
          content = ds_profiles["content"]
          label = content["dsLabel"].split('/').last
          results << {
            id: 'content', title: label,
            mime_type: content["dsMIME"], url: url_for_content("info:fedora/#{document[:id]}/content", File.extname(label).sub(/^\./,''))
          }
        end
      end
      return results

    else
      return []
    end
  end

  def url_for_content(key, mime)
    parts = key.split('/')
    ext = mime.split('/')[-1].downcase
    bytestream_content_url(catalog_id: parts[1], bytestream_id: parts[2], format: ext)
  end
end