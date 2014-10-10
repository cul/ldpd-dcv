module Dcv::CdnHelper

  def thumbnail_url(pid)
    DCV_CONFIG['cdn_url'] + "/images/#{pid}/square/256.jpg"
  end

end
