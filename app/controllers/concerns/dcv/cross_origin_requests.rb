module Dcv::CrossOriginRequests
  extend ActiveSupport::Concern

  def cors_headers(content_type: 'application/ld+json', allow_origin: '*')
    # CORS support: Any site should be able to do a cross-domain info request
    response.headers['Access-Control-Allow-Origin'] = allow_origin
    response.headers['Content-Type'] = content_type
    expires_in(1.day, public: true)
  end
end
