# frozen_string_literal: true

require 'active_storage/errors'

module ActiveStorage
  # Raised when a file was not yet moved from a staging bucket to a main one.
  class FileNotReadyError < Error; end
end
