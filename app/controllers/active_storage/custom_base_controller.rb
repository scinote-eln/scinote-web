# frozen_string_literal: true

# The base controller for all ActiveStorage controllers.
module ActiveStorage
  class CustomBaseController < ApplicationController
    include ActiveStorage::SetCurrent
  end
end
