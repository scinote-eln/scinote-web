module Api
  class AzureJwt
    require 'jwt'

    KEYS_CACHING_PERIOD = 7.days

    LEEWAY = 30

    def self.fetch_rsa_key(k_id, app_id)
      cache_key = "api_azure_ad_rsa_key_#{k_id}"
      Rails.cache.fetch(cache_key, expires_in: KEYS_CACHING_PERIOD) do
        settings = ApplicationSettings.instance
        provider_conf = settings.values['azure_ad_apps']&.find { |v| v['app_id'] == app_id }
        raise JWT::VerificationError, 'Azure AD: No application configured with such ID' unless provider_conf

        conf_url = provider_conf['conf_url']
        keys_url = JSON.parse(Net::HTTP.get(URI(conf_url)))['jwks_uri']
        data = JSON.parse(Net::HTTP.get(URI.parse(keys_url)))
        verif_key = data['keys'].find { |key| key['kid'] == k_id }
        raise JWT::VerificationError, 'Azure AD: No keys from key endpoint match the key in the token' unless verif_key

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
      raise JWT::VerificationError, 'Azure AD: No Key ID in token header' unless k_id

      # Now search for matching app variables in configuration
      app_id = unverified_token[0]['aud']
      settings = ApplicationSettings.instance
      provider_conf = settings.values['azure_ad_apps']&.find { |v| v['app_id'] == app_id }
      raise JWT::VerificationError, 'Azure AD: No application configured with such ID' unless provider_conf

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
        iss: provider_conf['iss'],
        nbf_leeway: LEEWAY
      )
      [HashWithIndifferentAccess.new(payload), HashWithIndifferentAccess.new(header)]
    end
  end
end
