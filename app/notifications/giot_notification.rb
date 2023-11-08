# frozen_string_literal: true

class GiotNotification < BaseNotification
  def message; end

  def self.subtype
    :giot_activity
  end

  def title; end
end
