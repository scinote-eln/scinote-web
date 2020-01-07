# frozen_string_literal: true

module OmniAuth
  module Strategies
    class CustomAzureActiveDirectory < AzureActiveDirectory
      include OmniAuth::Strategy

      option :openid_config_url
      option :sign_in_policy

      # Azure doesn't allow query params in callback URL
      def callback_url
        full_host + script_name + callback_path
      end

      def openid_config_url
        options[:openid_config_url]
      end

      def authorize_endpoint_url
        uri = URI(openid_config['authorization_endpoint'])
        params = {
          client_id: client_id,
          redirect_uri: callback_url,
          response_mode: response_mode,
          response_type: response_type,
          nonce: new_nonce,
          scope: 'openid'
        }
        params[:p] = options[:sign_in_policy] if options[:sign_in_policy].present?

        uri.query = URI.encode_www_form(params)
        uri.to_s
      end

      def validate_and_parse_id_token(id_token)
        jwt_claims, jwt_header = Api::AzureJwt.decode(id_token)
        return jwt_claims, jwt_header if jwt_claims['nonce'] == read_nonce

        raise JWT::DecodeError, 'Returned nonce did not match.'
      end
    end
  end
end

OmniAuth.config.add_camelization 'custom_azure_activedirectory', 'CustomAzureActiveDirectory'
