module Dcv::CdnHelper

  def zoomable_image_exists?(pid)
    url_to_check = "https://repository-cache.cul.columbia.edu/images/#{pid}.jp2"
    uri = URI.parse(url_to_check)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    json_response = JSON(response.body)
    return json_response['available']
  end

end
