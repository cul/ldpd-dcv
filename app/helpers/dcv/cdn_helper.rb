module Dcv::CdnHelper

  def zoomable_image_exists?(pid)
    url_to_check = "https://repository-cache.cul.columbia.edu/images/#{pid}/jp2.json"
    uri = URI.parse(url_to_check)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    json_response = JSON(response.body)
    return json_response['available']
  end

  def get_asset_url(conditions)
    return DCV_CONFIG['cdn_url'] + "/images/#{conditions[:id]}/#{conditions[:type]}/#{conditions[:size]}.#{conditions[:format]}"
  end

  def get_resolved_asset_url(conditions)
    return DCV_CONFIG['cdn_url'] + "/images/#{identifier_to_pid(conditions[:id])}/#{conditions[:type]}/#{conditions[:size]}.#{conditions[:format]}"
  end

  def get_asset_info_url(conditions)
    return  DCV_CONFIG['cdn_url'] + "/images/#{conditions[:id]}/#{conditions[:image_format]}.json"
  end

  def get_resolved_asset_info_url(conditions)
    return DCV_CONFIG['cdn_url'] + "/images/#{identifier_to_pid(conditions[:id])}/#{conditions[:image_format]}.json"
  end

  def get_iiif_zoom_info_url(conditions)
    return  DCV_CONFIG['cdn_url'] + "/iiif/#{conditions[:id]}/info.json"
  end

  def get_resolved_iiif_zoom_info_url(conditions)
    return  DCV_CONFIG['cdn_url'] + "/iiif/#{identifier_to_pid(conditions[:id])}/info.json"
  end

  # Placeholder image methods

  # Returns 256x256 placeholder image
  def get_non_image_thumbnail_url(type)
    # TODO: Handle different types
    # TODO: Actually use a real placeholder image when we have one

    # For now, always return the same image
    return image_url('durst/Durst019-lr.jpg')
  end

end
