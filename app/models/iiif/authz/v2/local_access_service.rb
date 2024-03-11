class Iiif::Authz::V2::LocalAccessService
  include Dcv::AccessLevels
  ACTIVE = 'active'
  EXTERNAL = 'external'
  KIOSK = 'kiosk'

  attr_reader :id, :canvas, :route_helper

  def initialize(canvas, route_helper:, profile:)
    @canvas = canvas
    @profile = profile
    @id = (@profile == ACTIVE) ? route_helper.iiif_login_url : route_helper.iiif_kiosk_url
    @route_helper = route_helper
    @profile = profile
  end

  def token_service
    use_format = 'json' unless @profile == ACTIVE
    Iiif::Authz::V2::AccessTokenService.new(canvas, route_helper: route_helper, format: use_format).to_h
  end

  def to_h
    access_service = IIIF_TEMPLATES['v2_access_service'].deep_dup
    access_service['service'] << token_service
    access_service['profile'] = @profile
    access_service['id'] = @id unless @profile == EXTERNAL
    case @profile
    when ACTIVE
      access_service['label'] = { 'en' => ["#{I18n.t('blacklight.application_name')} Users"] }
    when KIOSK
      access_service['label'] = { 'en' => ["#{I18n.t('blacklight.application_name')} Reading Rooms"] }
    when EXTERNAL
      access_service['label'] = { 'en' => ["#{I18n.t('blacklight.application_name')} Sessions"] }
    end      
    access_service
  end
end
