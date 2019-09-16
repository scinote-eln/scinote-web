# frozen_string_literal: true

# The base controller for all ActiveStorage controllers.
module ActiveStorage
  class BaseController < ApplicationController
    include ActiveStorage::SetCurrent

    before_action do
      ActiveStorage::Current.host = request.base_url
    end
  end
end
