# frozen_string_literal: true

module TokenAuthentication
  extend ActiveSupport::Concern

  private

  def azure_jwt_auth
    return unless @token_iss.match?(%r{windows.net/|microsoftonline.com/})

    token_payload, = Api::AzureJwt.decode(@token)
    @current_user = User.from_azure_jwt_token(token_payload)
    raise JWT::InvalidPayload, I18n.t('api.core.no_azure_user_mapping') unless current_user
  end

  def authenticate_request!
    @token = request.headers['Authorization']&.sub('Bearer ', '')
    raise JWT::VerificationError, I18n.t('api.core.missing_token') unless @token

    check_token_revocation!

    @token_iss = Api::CoreJwt.read_iss(@token)
    raise JWT::InvalidPayload, I18n.t('api.core.no_iss') unless @token_iss

    Extends::API_PLUGABLE_AUTH_METHODS.each do |auth_method|
      method(auth_method).call
      return true if current_user
    end

    # Default token implementation
    unless @token_iss == Rails.configuration.x.core_api_token_iss
      raise JWT::InvalidPayload, I18n.t('api.core.wrong_iss')
    end

    payload = Api::CoreJwt.decode(@token)
    @current_user = User.find_by(id: payload['sub'])
    raise JWT::InvalidPayload, I18n.t('api.core.no_user_mapping') unless current_user
  end

  def check_token_revocation!
    if Doorkeeper::AccessToken.where.not(revoked_at: nil).exists?(token: @token)
      raise JWT::VerificationError, I18n.t('api.core.expired_token')
    end
  end
end
