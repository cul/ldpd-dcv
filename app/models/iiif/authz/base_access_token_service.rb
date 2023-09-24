class Iiif::Authz::BaseAccessTokenService
  attr_reader :id, :canvas, :route_helper

  def initialize(canvas, route_helper:, format: nil)
    @canvas = canvas
    @id = route_helper.bytestream_token_url({catalog_id: canvas.solr_document.id, bytestream_id: 'content', format: format}.compact)
    @route_helper = route_helper
  end

  # this token only provides a Bearer-Token to verify the authz flow
  # access should continue to be verified at the asset/bytestream level 
  def self.token(document_id)
    token_src = "id=#{document_id}&#{DCV_CONFIG.dig('iiif','authz','shared_secret')}"
    Base64.urlsafe_encode64(Digest::SHA256.digest(token_src))
  end
end