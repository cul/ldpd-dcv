class Iiif::Authz::V1::AccessTokenService < Iiif::Authz::BaseAccessTokenService
  def to_h
    access_token_service = IIIF_TEMPLATES['v1_access_token_service'].deep_dup
    access_token_service['@id'] = @id
    access_token_service
  end
end