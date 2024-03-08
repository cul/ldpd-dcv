module Dcv::CrossOriginRequests
  extend ActiveSupport::Concern

  def request_origin(default = '*')
    request.headers['Origin'] || params[:origin] || default
  end

  def cors_headers(content_type: 'application/ld+json', allow_origin: '*', allow_credentials: false, mark_public: true, allow_headers: [])
    # CORS support: Any site should be able to do a cross-domain info request
    response.headers['Access-Control-Allow-Origin'] = allow_origin
    response.headers['Content-Type'] = content_type
    if allow_credentials && allow_origin && allow_origin != '*'
      response.headers['Access-Control-Allow-Credentials'] = 'true'
    end
    unless allow_headers.blank?
      response.headers['Access-Control-Allow-Headers'] = Array(allow_headers).join(',')
    end
    expires_in(1.day, public: true) if mark_public
  end
end
