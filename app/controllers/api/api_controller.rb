module Api
  class ApiController < ActionController::API
    attr_reader :iss
    attr_reader :token
    attr_reader :current_user

    before_action :load_token, except: %i(authenticate status health)
    before_action :load_iss, except: %i(authenticate status health)
    before_action :authenticate_request!, except: %i(authenticate status health)

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

    def authenticate
      if auth_params[:grant_type] == 'password'
        user = User.find_by_email(auth_params[:email])
        unless user && user.valid_password?(auth_params[:password])
          raise StandardError, 'Default: Wrong user password'
        end
        payload = { user_id: user.id }
        token = CoreJwt.encode(payload)
        render json: { token_type: 'bearer', access_token: token }
      else
        raise StandardError, 'Default: Wrong grant type in request'
      end
    end

    private

    def load_token
      if request.headers['Authorization']
        @token =
          request.headers['Authorization'].scan(/Bearer (.*)$/).flatten.last
      end
      raise StandardError, 'Common: No token in the header' unless @token
    end

    def azure_jwt_auth
      return unless iss =~ %r{windows.net/|microsoftonline.com/}
      token_payload, = Api::AzureJwt.decode(token)
      @current_user = User.from_azure_jwt_token(token_payload)
      unless current_user
        raise JWT::InvalidPayload, 'Azure AD: User mapping not found'
      end
    end

    def authenticate_request!
      Extends::API_PLUGABLE_AUTH_METHODS.each do |auth_method|
        method(auth_method).call
        return true if current_user
      end

      # Default token implementation
      unless iss == Api.configuration.core_api_token_iss
        raise JWT::InvalidPayload, 'Default: Wrong ISS in the token'
      end
      payload = CoreJwt.decode(token)
      @current_user = User.find_by_id(payload['user_id'])
      unless current_user
        raise JWT::InvalidPayload, 'Default: User mapping not found'
      end

      # Implement sliding sessions, i.e send new token in case of successful
      # authorization and when tokens TTL reached specific value (to avoid token
      # generation on each request)
      if CoreJwt.refresh_needed?(payload)
        new_token = CoreJwt.encode(user_id: current_user.id)
        response.headers['X-Access-Token'] = new_token
      end
    end

    def load_iss
      @iss = CoreJwt.read_iss(token)
      raise JWT::InvalidPayload, 'Common: Missing ISS in the token' unless @iss
    end

    def auth_params
      params.permit(:grant_type, :email, :password)
    end
  end
end
