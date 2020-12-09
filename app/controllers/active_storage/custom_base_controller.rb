# frozen_string_literal: true

# The base controller for all ActiveStorage controllers.
module ActiveStorage
  class CustomBaseController < ApplicationController
<<<<<<< HEAD
<<<<<<< HEAD
    include TokenAuthentication
    include ActiveStorage::SetCurrent

    prepend_before_action :authenticate_request!, if: -> { request.headers['Authorization'].present? }
    skip_before_action :authenticate_user!, if: -> { current_user.present? }

    private

    def stream(_blob)
      raise NotImplementedError
=======
    include ActiveStorage::SetCurrent

    before_action do
      ActiveStorage::Current.host = request.base_url
>>>>>>> Initial commit of 1.17.2 merge
    end
=======
    include TokenAuthentication
    include ActiveStorage::SetCurrent

    prepend_before_action :authenticate_request!, if: -> { request.headers['Authorization'].present? }
    skip_before_action :authenticate_user!, if: -> { current_user.present? }
>>>>>>> Pulled latest release
  end
end
