# frozen_string_literal: true

class Notification < ApplicationRecord
  has_many :user_notifications, inverse_of: :notification, dependent: :destroy
  has_many :users, through: :user_notifications
  belongs_to :generator_user, class_name: 'User', optional: true

  include Noticed::Model
  belongs_to :recipient, polymorphic: true

  enum type_of: Extends::NOTIFICATIONS_TYPES

  private

  def can_send_to_user?(_user)
    true # overridable send permission method
  end
end
