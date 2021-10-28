# frozen_string_literal: true

module TimestampableModel
  extend ActiveSupport::Concern

  included do
    attributes :created_at, :updated_at
  end
end
