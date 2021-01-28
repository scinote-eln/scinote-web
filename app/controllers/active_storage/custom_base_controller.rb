# frozen_string_literal: true

# The base controller for all ActiveStorage controllers.
module ActiveStorage
  class CustomBaseController < ApplicationController
    include TokenAuthentication
    include ActiveStorage::SetCurrent

    prepend_before_action :authenticate_request!, if: -> { request.headers['Authorization'].present? }
    skip_before_action :authenticate_user!, if: -> { current_user.present? }

    private

    def stream(_blob)
      raise NotImplementedError
    end
  end
end
