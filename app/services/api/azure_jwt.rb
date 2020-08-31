module Api
  class AzureJwt
    require 'jwt'

    KEYS_CACHING_PERIOD = 7.days

    LEEWAY = 30

    def self.fetch_rsa_key(k_id, app_id)
      cache_key = "api_azure_ad_rsa_key_#{k_id}"
      Rails.cache.fetch(cache_key, expires_in: KEYS_CACHING_PERIOD) do
        conf_url = Rails.configuration.x.azure_ad_apps[app_id][:conf_url]
        keys_url = JSON.parse(Net::HTTP.get(URI(conf_url)))['jwks_uri']
        data = JSON.parse(Net::HTTP.get(URI.parse(keys_url)))
        verif_key = data['keys'].find { |key| key['kid'] == k_id }
        unless verif_key
          raise JWT::VerificationError,
                'Azure AD: No keys from key endpoint match the key in the token'
        end
        JSON::JWK.new(verif_key).to_key.to_s
      end
    end

    def self.decode(token)
      # First, extract key id from token header,
      # [1] is position of the header.
      # We will use this ID to fetch correct public key needed for
      # verification of the token signature
      unverified_token = JWT.decode(token, nil, false)

      k_id = unverified_token[1]['kid']
      unless k_id
        raise JWT::VerificationError, 'Azure AD: No Key ID in token header'
      end

      # Now search for matching app variables in configuration
      app_id = unverified_token[0]['aud']
      app_config = Rails.configuration.x.azure_ad_apps[app_id]
      unless app_config
        raise JWT::VerificationError,
              'Azure AD: No application configured with such ID'
      end

      # Decode token payload and verify it's signature.
      payload, header = JWT.decode(
        token,
        OpenSSL::PKey::RSA.new(fetch_rsa_key(k_id, app_id)),
        true,
        algorithm: 'RS256',
        verify_expiration: true,
        verify_aud: true,
        aud: app_id,
        verify_iss: true,
        iss: app_config[:iss],
        nbf_leeway: LEEWAY
      )
      [HashWithIndifferentAccess.new(payload), HashWithIndifferentAccess.new(header)]
    end
  end
end
