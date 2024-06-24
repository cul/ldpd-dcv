class Iiif::Authz::V2::ProbeService::Response
  include Dcv::AccessLevels
  attr_reader :document, :route_helper, :bytestream_id

  def initialize(document:, bytestream_id:, ability_helper:, route_helper:, remote_ip:, authorization: nil)
    @document = document
    @ability_helper = ability_helper
    @route_helper = route_helper
    @remote_ip = remote_ip
    @bytestream_id = bytestream_id
    @authorization = authorization
  end

  def redirect_location_properties(ability_helper=@ability_helper)
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

  def token_authorizer
    @token_authorizer ||= TokenAuthorizer.new(authorization: @authorization, remote_ip: @remote_ip)
  end

  def token_authorized?
    token_authorizer.can_access_asset?(@document) 
  end

  def to_h
    probe_response = IIIF_TEMPLATES['v2_probe_response'].deep_dup
    probe_response[:id] = route_helper.bytestream_probe_url(catalog_id: @document.id, bytestream_id: bytestream_id)
    if @ability_helper.can?(Ability::ACCESS_ASSET, @document) && @ability_helper.reading_room_client?
      probe_response.merge!(redirect_location_properties)
    elsif token_authorized?
      probe_response.merge!(redirect_location_properties(token_authorizer))
    else
      no_token = @authorization.blank?
      has_id_policy = @document.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_AFFILIATION)
      logged_in = !!@ability_helper.current_user
      # not authorized
      if no_token || (has_id_policy && !logged_in)
        probe_response.merge!(status: 401, heading: "Login Required", note: "This resource may be visible to Columbia affiliates, please log in")
        probe_response.merge!(service: services(id: probe_response[:id], document: @document, route_helper: @route_helper, ability_helper: @ability_helper))
      else
        probe_response.merge!(status: 403, heading: "Unauthorized", note: "Access to this resource is currently restricted; contact the reading room")
      end
    end
    probe_response
  end
  def services(id:, document:, route_helper:, ability_helper:)
    canvas = Iiif::Canvas.new(id: id, solr_document: document,
                              route_helper: route_helper, ability_helper: ability_helper)
    probe = Iiif::Authz::V2::ProbeService.new(canvas, route_helper: route_helper, ability_helper: ability_helper)
    probe.to_h['service']
  end
  class TokenAuthorizer
    def initialize(authorization:, remote_ip:)
      @authorization = authorization
      @remote_ip = remote_ip
    end

    def can_access_asset?(asset_doc)
      return false unless @authorization
      auth_type, auth_value = @authorization.split(' ')
      return false unless auth_type.downcase == 'bearer'
      secret = DCV_CONFIG.dig('iiif','authz','shared_secret')

      token_data = Iiif::Authz::V2::AccessTokenService.parse(auth_value, @remote_ip, secret)
      return true if token_data['aud'] == asset_doc.id
      token_data['aud'] == asset_doc.doi_identifier  
    end
  end
end