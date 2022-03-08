module Api
  class CoreJwt
    require 'jwt'
    KEY_SECRET = Rails.application.secrets.secret_key_base

    def self.encode(payload, expires_at = nil)
      if expires_at
        payload[:exp] = expires_at
      else
        payload[:exp] = Api.configuration.core_api_token_ttl.from_now.to_i
      end
      payload[:iss] = Api.configuration.core_api_token_iss
      JWT.encode(payload, KEY_SECRET, Api.configuration.core_api_sign_alg)
    end

    def self.decode(token)
      HashWithIndifferentAccess.new(
        JWT.decode(token, KEY_SECRET, Api.configuration.core_api_sign_alg)[0]
      )
    end

    def self.read_iss(token)
      HashWithIndifferentAccess.new(
        JWT.decode(token, nil, false)[0]
      )[:iss].to_s
    end

    # Method used by Doorkeeper for custom tokens
    def self.generate(options = {})
      encode(
        { sub: options[:resource_owner_id] },
        options[:expires_in].seconds.from_now.to_i
      )
    end
  end
end
