module Dcv::WowzaTokenUrlHelper
  def wowza_media_token_url(asset_pid)
    wowza_config = DCV_CONFIG['media_streaming']['wowza']
    ds = Cul::Hydra::Fedora.ds_for_opts({pid: asset_pid, dsid: 'access'})
    access_copy_location = ds.present? ? Addressable::URI.unencode(ds.dsLocation).gsub(/^file:/, '') : ''

    Wowza::SecureToken::Params.new({
      stream: wowza_config['application'] + '/_definst_/' + (access_copy_location.downcase.index('.mp3') ? 'mp3:' : 'mp4:') + access_copy_location.gsub(/^\//, ''),
      secret: wowza_config['shared_secret'],
      client_ip: wowza_config['client_ip_override'] || request.remote_ip,
      starttime: Time.now.to_i,
      endtime: Time.now.to_i + wowza_config['token_lifetime'].to_i,
      prefix: wowza_config['token_prefix']
    }).to_url_with_token_hash(wowza_config['host'], wowza_config['ssl_port'], 'hls-ssl')
  end
end
