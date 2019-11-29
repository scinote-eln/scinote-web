# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    attr_reader :iss
    attr_reader :token
    attr_reader :current_user

    before_action :authenticate_request!, except: %i(status health)

    rescue_from StandardError do |e|
      logger.error e.message
      logger.error e.backtrace.join("\n")
      render json: {}, status: :bad_request
    end

    rescue_from JWT::DecodeError,
                JWT::InvalidPayload,
                JWT::VerificationError do |e|
      logger.error e.message
      render json: { message: I18n.t('api.core.invalid_token') },
             status: :unauthorized
    end

    rescue_from JWT::ExpiredSignature do |e|
      logger.error e.message
      render json: { message: I18n.t('api.core.expired_token') },
             status: :unauthorized
    end

    def initialize
      super
      @iss = nil
    end

    def health
      User.new && Team.new && Project.new
      User.first if params[:db]
      if Rails.application.secrets.system_notifications_uri.present? &&
         Rails.application.secrets.system_notifications_channel.present? &&
         !Notifications::SyncSystemNotificationsService.available?
        return render plain: 'SYSTEM NOTIFICATIONS SERVICE CHECK FAILED', status: :error
      end
      render plain: 'RUNNING'
    end

    def status
      response = {}
      response[:message] = I18n.t('api.core.status_ok')
      response[:versions] = []
      Extends::API_VERSIONS.each do |ver|
        response[:versions] << { version: ver, baseUrl: "/api/#{ver}/" }
      end
      render json: response, status: :ok
    end

    private

    def azure_jwt_auth
      return unless iss =~ %r{windows.net/|microsoftonline.com/}
      token_payload, = Api::AzureJwt.decode(token)
      @current_user = User.from_azure_jwt_token(token_payload)
      unless current_user
        raise JWT::InvalidPayload, I18n.t('api.core.no_azure_user_mapping')
      end
    end

    def authenticate_request!
      @token = request.headers['Authorization']&.sub('Bearer ', '')
      unless @token
        raise JWT::VerificationError, I18n.t('api.core.missing_token')
      end

      @iss = CoreJwt.read_iss(token)
      raise JWT::InvalidPayload, I18n.t('api.core.no_iss') unless @iss

      Extends::API_PLUGABLE_AUTH_METHODS.each do |auth_method|
        method(auth_method).call
        return true if current_user
      end

      # Default token implementation
      unless iss == Rails.configuration.x.core_api_token_iss
        raise JWT::InvalidPayload, I18n.t('api.core.wrong_iss')
      end
      payload = CoreJwt.decode(token)
      @current_user = User.find_by_id(payload['sub'])
      unless current_user
        raise JWT::InvalidPayload, I18n.t('api.core.no_user_mapping')
      end
    end

    def auth_params
      params.permit(:grant_type, :email, :password)
    end
  end
end
