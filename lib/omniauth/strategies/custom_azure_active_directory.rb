# frozen_string_literal: true

module OmniAuth
  module Strategies
    class CustomAzureActiveDirectory < AzureActivedirectoryV2
      include OmniAuth::Strategy

      option :name, 'customazureactivedirectory'

      def client
        omni_client = super
        begin
          app_conf =
            Rails.cache.fetch("ad_app_conf_#{options[:client_id]}", expires_in: 1.day) do
              JSON.parse(Net::HTTP.get(URI(options[:conf_url])))
            end
          omni_client.options[:authorize_url] = app_conf['authorization_endpoint']
          omni_client.options[:token_url] = app_conf['token_endpoint']
        rescue StandardError => e
          Rails.logger.error('Failed to load OAuth2 configuration from the remote server! Using defaults.')
          Rails.logger.error(e.message)
        end
        omni_client
      end

      def raw_info
        if @raw_info.nil?
          id_token_data   = ::JWT.decode(access_token.params['id_token'], nil, false).first rescue {}
          auth_token_data = ::JWT.decode(access_token.token,              nil, false).first rescue {}
          @raw_info = auth_token_data.merge(id_token_data)
        end

        @raw_info
      end
    end
  end
end

OmniAuth.config.add_camelization 'custom_azure_activedirectory', 'CustomAzureActiveDirectory'
