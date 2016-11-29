module Dcv::CdnHelper

  def zoomable_image_exists_for_resource?(pid)
    url_to_check = DCV_CONFIG['cdn_url'] + "/iiif/#{pid}/info.json"
    uri = URI.parse(url_to_check)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    return response.code == '200'
  end

  def get_asset_url(conditions)
    return DCV_CONFIG['cdn_url'] + "/iiif/2/#{conditions[:id]}/#{conditions[:type]}/!#{conditions[:size]},#{conditions[:size]}/0/native.#{conditions[:format]}"
  end

  def get_resolved_asset_url(conditions)
    conditions[:id] = identifier_to_pid(conditions[:id])
    return get_asset_url(conditions)
  end

  def get_asset_info_url(conditions)
    #return  DCV_CONFIG['cdn_url'] + "/images/#{conditions[:id]}/#{conditions[:image_format]}.json"
    get_iiif_zoom_info_url(conditions)
  end

  def get_resolved_asset_info_url(conditions)
    #return DCV_CONFIG['cdn_url'] + "/images/#{identifier_to_pid(conditions[:id])}/#{conditions[:image_format]}.json"
    get_resolved_iiif_zoom_info_url(conditions)
  end

  def get_iiif_zoom_info_url(conditions)
    return  DCV_CONFIG['cdn_url'] + "/iiif/#{conditions[:id]}/info.json"
  end

  def get_resolved_iiif_zoom_info_url(conditions)
    return  DCV_CONFIG['cdn_url'] + "/iiif/#{identifier_to_pid(conditions[:id])}/info.json"
  end

  def thumbnail_url(document, options={})
    schema_image = Array(document[ActiveFedora::SolrService.solr_name('schema_image', :symbol)]).first

    id = schema_image ? schema_image.split('/')[-1] : document.id
    get_asset_url(id: id, size: 256, type: 'featured', format: 'jpg')
  end

  def thumbnail_for_doc(document, image_options={})
    image_tag thumbnail_url(document), image_options
  end

  def thumbnail_placeholder(document, image_options={})
    image_tag image_url('file-placeholder.png')
  end
end
