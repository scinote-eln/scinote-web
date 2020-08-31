# frozen_string_literal: true

module RepositoryImportParser
  module Util
    def self.split_by_delimiter(text:, delimiter:)
      # If pattern is a single space, str is split on whitespace, with leading whitespace, new lines, etc...
      if delimiter == ' '
        text.split(/ /).reject(&:empty?)
      else
        text.split(delimiter)
      end
    end
  end
end
