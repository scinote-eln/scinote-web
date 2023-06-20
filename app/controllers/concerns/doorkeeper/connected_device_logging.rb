# frozen_string_literal: true

module Doorkeeper
  module ConnectedDeviceLogging
    extend ActiveSupport::Concern

    included do
      after_action :log_connected_device, only: :create
    end

    private

    def log_connected_device
      return if @authorize_response.is_a?(Doorkeeper::OAuth::ErrorResponse)

      ConnectedDevice.from_request_headers(request.headers, @authorize_response&.token)
    end
  end
end
