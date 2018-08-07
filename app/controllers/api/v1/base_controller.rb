# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApiController
      rescue_from ActionController::ParameterMissing do |e|
        logger.error e.message
        render json: {}, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        logger.error e.message
        render json: {}, status: :not_found
      end
    end
  end
end
