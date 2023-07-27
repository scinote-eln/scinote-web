# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    include TokenAuthentication

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

    def filter_timestamp_range(records)
      from = params.dig(:create_date_start)
      to = params.dig(:create_date_end)
      column = 'created_at'
      if from.blank? || to.blank?
        from = params.dig(:update_date_start)
        to = params.dig(:update_date_end)
        column = 'updated_at'
      end

      return records if from.blank? || to.blank?

      if column == 'created_at'
        records.where(created_at: (from..to))
      else
        records.where(updated_at: (from..to))
      end
    end
  end
end
