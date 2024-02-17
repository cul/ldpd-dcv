class Iiif::Authz::V2::ProbeService::Response
  include Dcv::AccessLevels
  attr_reader :document, :ability_helper, :route_helper, :bytestream_id

  def initialize(document:, bytestream_id:, ability_helper:, route_helper:, remote_ip:)
    @document = document
    @ability_helper = ability_helper
    @route_helper = route_helper
    @remote_ip = remote_ip
    @bytestream_id = bytestream_id
  end

  def redirect_location_properties
    if (@document.fetch('dc_type_ssm',[]) & ['Sound', 'Audio', 'MovingImage', 'Video']).present?
      return {
        status: 302,
        location: Dcv::Utils::CdnUtils.wowza_media_token_url(@document, ability_helper, @remote_ip),
        format: 'application/vnd.apple.mpegurl'
      }
    end
    preferred_bytestream_id = Dcv::Utils::UrlUtils.preferred_content_bytestream(@document)
    return { status: 302, location: route_helper.bytestream_content_url(catalog_id: @document.id, bytestream_id: preferred_bytestream_id) }
  end

  def to_h
    probe_response = IIIF_TEMPLATES['v2_probe_response'].deep_dup
    if @ability_helper.can?(Ability::ACCESS_ASSET, @document)
      probe_response.merge!(redirect_location_properties)
    else
      # not authorized
      if @document.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_AFFILIATION) && !@ability_helper.current_user
        probe_response.merge!(status: 401, heading: "Login Required", note: "This resource may be visible to Columbia affiliates, please log in")
      else
        probe_response.merge!(status: 403, heading: "Unauthorized", note: "Access to this resource is currently restricted; contact the reading room")
      end
    end
    probe_response[:id] = route_helper.bytestream_probe_url(catalog_id: @document.id, bytestream_id: bytestream_id)
    probe_response
  end
end