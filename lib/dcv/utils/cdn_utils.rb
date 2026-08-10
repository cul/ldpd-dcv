module Dcv::Utils::CdnUtils

  def self.random_cdn_url
    DCV_CONFIG['cdn_urls'].sample
  end

  def self.info_url(conditions)
    base_type = conditions.fetch(:base_type, 'standard')
    Dcv::Utils::CdnUtils.random_cdn_url + "/iiif/2/#{base_type}/#{conditions[:id]}/info.json"
  end

  # https://triclops.library.columbia.edu/iiif/2/standard/cul:44j0zpc8xq/full/!1280,1280/0/default.jpg
  def self.asset_url(conditions)
    box_width = conditions[:width] || conditions[:size]
    box_height = conditions[:height] || conditions[:size]
    base_type = conditions.fetch(:base_type, 'standard')
    Dcv::Utils::CdnUtils.random_cdn_url + "/iiif/2/#{base_type}/#{conditions[:id]}/#{conditions[:region]}/!#{box_width},#{box_height}/0/default.#{conditions[:format]}"
  end

  def self.archive_org_id_for_document(solr_doc)
    solr_doc.archive_org_identifier
  end

  def self.image_service(document, routes = nil)
    solr_doc =  document.is_a?(SolrDocument) ? document : SolrDocument.new(document)
    return Dcv::Utils::ImageService.for(solr_doc, routes)
  end

  def self.wowza_media_token_url(asset_doc, authorizer, remote_ip)
    asset_doc = SolrDocument.new(asset_doc) unless asset_doc.is_a? SolrDocument
    return unless authorizer.can_access_asset?(asset_doc)
    wowza_config = DCV_CONFIG.dig(:media_streaming,:wowza)
    unless wowza_config
      Rails.logger.warn("WARNING: no config available at DCV_CONFIG[:media_streaming][:wowza]")
      return
    end

    access_copy_location = wowza_access_copy_location_from_solr(asset_doc) || wowza_access_copy_location_from_fcrepo(asset_doc)
    Dcv::Utils::WowzaUtils.wowza_url_for_video_location(access_copy_location, remote_ip)
  end

  def self.wowza_access_copy_location_from_solr(asset_doc)
    object_profile = Array(asset_doc['object_profile_ssm']).first
    return nil if object_profile.blank?
    object_profile = JSON.load(object_profile)
    ds_profile = object_profile.dig("datastreams","access")
    return nil if ds_profile.blank?
    ds_location = ds_profile["dsLocation"]
    ds_location.present? ? file_uri_ds_location_to_file_path(ds_location) : nil
  end

  def self.wowza_access_copy_location_from_fcrepo(asset_doc)
    asset_pid = asset_doc[:pid] || asset_doc[:id]
    ds = Cul::Hydra::Fedora.ds_for_opts({pid: asset_pid, dsid: 'access'})
    ds.present? ? file_uri_ds_location_to_file_path(ds.dsLocation) : ''
  end

  def self.file_uri_ds_location_to_file_path(file_uri_ds_location)
    Addressable::URI.unencode(file_uri_ds_location).gsub(/^file:\/+/, '/')
  end
end
