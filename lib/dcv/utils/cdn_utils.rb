module Dcv::Utils::CdnUtils

  def self.random_cdn_url
    DCV_CONFIG['cdn_urls'].sample
  end

end
