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

    def self.refresh_needed?(payload)
      time_left = payload[:exp].to_i - Time.now.to_i
      return true if time_left < (Api.configuration.core_api_token_ttl.to_i / 2)
      false
    end
  end
end
