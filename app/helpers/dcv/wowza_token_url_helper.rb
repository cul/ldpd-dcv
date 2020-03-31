module Dcv::WowzaTokenUrlHelper
  def wowza_media_token_url(asset_doc)
    asset_doc = SolrDocument.new(asset_doc) unless asset_doc.is_a? SolrDocument
    return unless can_access_asset?(asset_doc)
    wowza_config = DCV_CONFIG['media_streaming']['wowza']

    access_copy_location = wowza_access_copy_location_from_solr(asset_doc) || wowza_access_copy_location_from_fcrepo(asset_doc)

    Wowza::SecureToken::Params.new({
      stream: wowza_config['application'] + '/_definst_/' + (access_copy_location.downcase.index('.mp3') ? 'mp3:' : 'mp4:') + access_copy_location.gsub(/^\//, ''),
      secret: wowza_config['shared_secret'],
      client_ip: wowza_config['client_ip_override'] || request.remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config['token_lifetime'].to_i,
      prefix: wowza_config['token_prefix']
    }).to_url_with_token_hash(wowza_config['host'], wowza_config['ssl_port'], 'hls-ssl')
  end

  def wowza_access_copy_location_from_solr(asset_doc)
    object_profile = Array(asset_doc['object_profile_ssm']).first
    return nil if object_profile.blank?
    object_profile = JSON.load(object_profile)
    ds_profile = object_profile.dig("datastreams","access")
    return nil if ds_profile.blank?
    ds_location = ds_profile["dsLocation"]
    ds_location.present? ? Addressable::URI.unencode(ds_location).gsub(/^file:/, '') : nil
  end

  def wowza_access_copy_location_from_fcrepo(asset_doc)
    asset_pid = asset_doc[:pid] || asset_doc[:id]
    ds = Cul::Hydra::Fedora.ds_for_opts({pid: asset_pid, dsid: 'access'})
    ds.present? ? Addressable::URI.unencode(ds.dsLocation).gsub(/^file:/, '') : ''
  end
end
