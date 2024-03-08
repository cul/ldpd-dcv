class Iiif::Authz::BaseAccessTokenService
  attr_reader :id, :canvas, :route_helper
  JWT_HEADER = { alg: 'HS256', typ: 'JWT' }.freeze

  def initialize(canvas, route_helper:, format: nil)
    @canvas = canvas
    @id = route_helper.bytestream_token_url({catalog_id: canvas.solr_document.id, bytestream_id: 'content', format: format}.compact)
    @route_helper = route_helper
  end

  # this token only provides a Bearer-Token to verify the authz flow
  # access should continue to be verified at the asset/bytestream level for downloads
  # probe service redirects will ideally have backend verification
  def self.token(document_id, remote_ip, issued_at, secret)
    token_payload = {
      'aud' => document_id,
      'loc' => remote_ip,
      'iat' => issued_at
    }
    token_header = Base64.urlsafe_encode64(JSON.generate(JWT_HEADER), padding: false).strip
    token_data = Base64.urlsafe_encode64(JSON.generate(token_payload), padding: false).strip
    jwt_signature = check_data(token_header, token_data, secret)
    "#{token_header}.#{token_data}.#{jwt_signature}"
  end

  def self.parse(token, remote_ip, secret)
    parsed_token = {}
    with_client_data(token, remote_ip, secret) { |data| parsed_token.merge!(data) if data.present? }
    parsed_token
  end

  def self.with_valid_data(token, secret)
    header, data, signature = token&.split('.')
    if data.present? && valid_jwt_signature?(secret, header, data, signature)
      yield JSON.load(Base64.decode64(data))
    else
      Rails.logger.warn("jwt signature could not be verified #{token}")
      yield Hash.new
    end
  end

  def self.with_current_data(token, secret)
    with_valid_data(token, secret) do |decoded_hash|
      if decoded_hash.present? 
        now = current_time
        if now >= decoded_hash['iat'] && now <= decoded_hash['iat'] + DCV_CONFIG.dig('media_streaming','wowza', 'token_lifetime').to_i
          yield decoded_hash
        else
          Rails.logger.warn("expired jwt #{token}")
          yield Hash.new
        end
      else
        yield decoded_hash
      end
    end
  end

  def self.with_client_data(token, remote_ip, secret)
    with_current_data(token, secret) do |current_hash|
      if current_hash.present? 
        if remote_ip == current_hash['loc']
          yield current_hash
        else
          Rails.logger.warn("client location changed #{remote_ip} #{token}")
          yield Hash.new
        end
      else
        yield current_hash
      end
    end
  end

  def self.check_data(header, data, secret)
    #TODO: pull digest algorithm out of jwt header
    hmac = OpenSSL::HMAC.digest('sha256', secret, "#{header}.#{data}")
    Base64.urlsafe_encode64(hmac, padding: false).strip
  end

  def self.valid_jwt_signature?(secret, header, data, signature)
    # compare proffered signature to stripped, unpadded hmac
    signature == check_data(header, data, secret)
  end

  private
    def self.current_time
      Time.now.utc.to_i
    end
end