class Iiif::Authz::V2::ExternalAccessService
  include Dcv::AccessLevels
  PROFILE = 'external'

  attr_reader :id, :canvas, :route_helper

  def initialize(canvas, route_helper:, **_args)
    @canvas = canvas
    @route_helper = route_helper
    @profile = PROFILE
  end

  def token_service
    Iiif::Authz::V2::AccessTokenService.new(canvas, route_helper: route_helper, format: 'json').to_h
  end

  def to_h
    access_service = IIIF_TEMPLATES['v2_access_service'].deep_dup
    access_service['id'] = 'info:dlc.library.columbia.edu'
    access_service['service'] << token_service
    access_service['profile'] = PROFILE
    access_service['label'] = { 'en' => ["#{I18n.t('blacklight.application_name')} Sessions"] }
    access_service
  end
end