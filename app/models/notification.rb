# frozen_string_literal: true

class Notification < ApplicationRecord
  has_many :user_notifications, inverse_of: :notification, dependent: :destroy

  include Noticed::Model
  belongs_to :recipient, polymorphic: true

  private

  def can_send_to_user?(_user)
    true # overridable send permission method
  end
end
