# frozen_string_literal: true

class DeliveryNotification < BaseNotification
  def self.subtype
    :delivery
  end

  def message
    params[:message]
  end

  def title
    params[:title]
  end
end
