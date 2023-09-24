class Iiif::Authz::V2::ProbeService
  include Dcv::AccessLevels
  AMI_TYPES = [Iiif::Type::V3::SOUND, Iiif::Type::V3::VIDEO]

  attr_reader :id, :canvas, :route_helper, :ability_helper

  def initialize(canvas, route_helper:, ability_helper:, **_args)
    @canvas = canvas
    @route_helper = route_helper
    catalog_id = canvas.solr_document.id
    @id = route_helper.bytestream_probe_url({ catalog_id: catalog_id, bytestream_id: 'content' })
    @ability_helper = ability_helper
    @in_reading_room = ability_helper.reading_room_client?
  end

  def to_h
    probe_service = IIIF_TEMPLATES['v2_probe_service'].deep_dup
    probe_service['id'] = id
    offer_external = !public_access? && !requires_reading_room? && !in_reading_room?
    offer_kiosk = in_reading_room? || requires_reading_room? || (streaming_media? && public_access?)
    offer_active = !public_access? && !requires_reading_room?
    probe_service['service'] <<  access_service('external') if offer_external
    probe_service['service'] <<  access_service('kiosk') if offer_kiosk
    probe_service['service'] <<  access_service('active') if offer_active
    probe_service
  end

  def in_reading_room?
    @in_reading_room
  end

  def public_access?
    solr_document = canvas.solr_document
    permits_public = solr_document.fetch('access_control_levels_ssim',[ACCESS_LEVEL_PUBLIC]).include?(ACCESS_LEVEL_PUBLIC)
    return true if permits_public || solr_document.fetch('access_control_levels_ssim', nil).blank?
    has_public_embargo = solr_document.fetch('access_control_levels_ssim',[]) == [ACCESS_LEVEL_EMBARGO]
    has_public_embargo && embargo_expired?(solr_document)
  end

  def requires_reading_room?
    solr_document = canvas.solr_document
    permits_affils = solr_document.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_AFFILIATION)
    return false if permits_affils || public_access?
    return solr_document.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_ONSITE)
  end

  # all streaming media requires a token
  def streaming_media?
    AMI_TYPES.include?(canvas.canvas_type)
  end

  def required?
    !public_access? || streaming_media?
  end

  def access_service(profile)
    case profile
    when 'external'
      Iiif::Authz::V2::ExternalAccessService.new(canvas, route_helper: route_helper, profile: profile).to_h
    else
      Iiif::Authz::V2::LocalAccessService.new(canvas, route_helper: route_helper, profile: profile).to_h
    end
  end

  def as_json(opts = {})
    to_h
  end

  def to_json
    JSON.pretty_generate(as_json)
  end

  private

  def embargo_expired?(solr_document)
    solr_document['access_control_embargo_dtsi'].to_s <= Time.now.to_s
  end
end