module Api
  class ApiController < ActionController::Base
    attr_reader :iss
    attr_reader :token
    attr_reader :current_user

    before_action :load_token, except: %i(authenticate status health)
    before_action :load_iss, except: %i(authenticate status health)
    before_action :authenticate_request!, except: %i(authenticate status health)

    rescue_from StandardError do |e|
      logger.error e.message
      render json: {}, status: :bad_request
    end

    rescue_from JWT::InvalidPayload, JWT::DecodeError do |e|
      logger.error e.message
      render json: { message: I18n.t('api.core.invalid_token') },
             status: :unauthorized
    end

    def initialize
      super
      @iss = nil
    end

    def health
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
          raise StandardError, 'Wrong user password'
        end
        payload = { user_id: user.id }
        token = CoreJwt.encode(payload)
        render json: { token_type: 'bearer', access_token: token }
      else
        raise StandardError, 'Wrong grant type in request'
      end
    end

    private

    def load_token
      if request.headers['Authorization']
        @token =
          request.headers['Authorization'].scan(/Bearer (.*)$/).flatten.last
      end
      raise StandardError, 'No token in the header' unless @token
    end

    def authenticate_request!
      Extends::API_PLUGABLE_AUTH_METHODS.each do |auth_method|
        method(auth_method).call
        return true if current_user
      end
      # Check request header for proper auth token
      payload = CoreJwt.decode(token)
      @current_user = User.find_by_id(payload['user_id'])
      # Implement sliding sessions, i.e send new token in case of successful
      # authorization and when tokens TTL reached specific value (to avoid token
      # generation on each request)
      if CoreJwt.refresh_needed?(payload)
        new_token = CoreJwt.encode(user_id: @current_user.id)
        response.headers['X-Access-Token'] = new_token
      end
    rescue JWT::ExpiredSignature
      render json: { message: I18n.t('api.core.expired_token') },
             status: :unauthorized
    end

    def load_iss
      @iss = CoreJwt.read_iss(token)
      raise JWT::InvalidPayload, 'Wrong ISS in the token' unless @iss
    end

    def auth_params
      params.permit(:grant_type, :email, :password)
    end
  end
end
