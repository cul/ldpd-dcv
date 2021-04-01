module Dcv::WowzaTokenUrlHelper
  def wowza_media_token_url(asset_doc)
    # pass self as authorization context
    Dcv::Utils::CdnUtils.wowza_media_token_url(asset_doc, self, request.remote_ip)
  end

  def wowza_access_copy_location_from_solr(asset_doc)
    Dcv::Utils::CdnUtils.wowza_access_copy_location_from_solr(asset_doc)
  end

  def wowza_access_copy_location_from_fcrepo(asset_doc)
    Dcv::Utils::CdnUtils.wowza_access_copy_location_from_fcrepo(asset_doc)
  end
end
