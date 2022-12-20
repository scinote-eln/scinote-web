# frozen_string_literal: true

module OmniAuth
  module Strategies
    class CustomAzureActiveDirectory < AzureActivedirectoryV2
      include OmniAuth::Strategy

      option :name, 'customazureactivedirectory'

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
