module Dcv::Utils::CdnUtils

  def self.random_cdn_url
    DCV_CONFIG['cdn_urls'].sample
  end

  def self.info_url(conditions)
    Dcv::Utils::CdnUtils.random_cdn_url + "/iiif/2/#{conditions[:id]}/info.json"
  end

  def self.asset_url(conditions)
    box_width = conditions[:width] || conditions[:size]
    box_height = conditions[:height] || conditions[:size]
    Dcv::Utils::CdnUtils.random_cdn_url + "/iiif/2/#{conditions[:id]}/#{conditions[:type]}/!#{box_width},#{box_height}/0/native.#{conditions[:format]}"
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

    Wowza::SecureToken::Params.new({
      stream: wowza_config[:application] + '/_definst_/' + (access_copy_location.downcase.index('.mp3') ? 'mp3:' : 'mp4:') + access_copy_location.gsub(/^\//, ''),
      secret: wowza_config[:shared_secret],
      client_ip: wowza_config[:client_ip_override] || remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config[:token_lifetime].to_i,
      prefix: wowza_config['token_prefix']
    }).to_url_with_token_hash(wowza_config[:host], wowza_config[:ssl_port], 'hls-ssl')
  end

  def self.wowza_access_copy_location_from_solr(asset_doc)
    object_profile = Array(asset_doc['object_profile_ssm']).first
    return nil if object_profile.blank?
    object_profile = JSON.load(object_profile)
    ds_profile = object_profile.dig("datastreams","access")
    return nil if ds_profile.blank?
    ds_location = ds_profile["dsLocation"]
    ds_location.present? ? Addressable::URI.unencode(ds_location).gsub(/^file:\/+/, '/') : nil
  end

  def self.wowza_access_copy_location_from_fcrepo(asset_doc)
    asset_pid = asset_doc[:pid] || asset_doc[:id]
    ds = Cul::Hydra::Fedora.ds_for_opts({pid: asset_pid, dsid: 'access'})
    ds.present? ? Addressable::URI.unencode(ds.dsLocation).gsub(/^file:\/+/, '/') : ''
  end
end
