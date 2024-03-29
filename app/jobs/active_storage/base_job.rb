# frozen_string_literal: true

require 'active_storage/custom_errors'

class ActiveStorage::BaseJob < ActiveJob::Base
  retry_on ActiveStorage::FileNotReadyError, attempts: 10, wait: :exponentially_longer
end
