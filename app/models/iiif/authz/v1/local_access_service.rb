class Iiif::Authz::V1::LocalAccessService
  include Dcv::AccessLevels
  LOGIN = 'http://iiif.io/api/auth/1/login'
  EXTERNAL = 'http://iiif.io/api/auth/1/external'
  KIOSK = 'http://iiif.io/api/auth/1/kiosk'

  attr_reader :id, :canvas, :route_helper

  def initialize(canvas, route_helper:, ability_helper:)
    @canvas = canvas
    @profile = (ability_helper.repository_ids_for_client.present?) ? KIOSK : LOGIN
    @id = (@profile == LOGIN) ? route_helper.iiif_login_url : route_helper.iiif_kiosk_url
    @route_helper = route_helper
  end

  def token_service
    Iiif::Authz::V1::AccessTokenService.new(canvas, route_helper: route_helper).to_h
  end

  def to_h
    access_service = IIIF_TEMPLATES['v1_access_service'].deep_dup
    access_service['service'] << token_service
    access_service['profile'] = @profile
    access_service['@id'] = @id unless @profile == EXTERNAL
    access_service['label'] = { en: [(@profile == KIOSK) ? "Columbia University Library Reading Rooms" : "Columbia University"] }
    access_service
  end
end