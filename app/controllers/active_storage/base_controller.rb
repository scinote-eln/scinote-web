# frozen_string_literal: true

# The base controller for all ActiveStorage controllers.
module ActiveStorage
  class BaseController < ApplicationController
    before_action do
      ActiveStorage::Current.host = request.base_url
    end
  end
end
