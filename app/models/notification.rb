class Notification < ApplicationRecord
  has_many :user_notifications, inverse_of: :notification, dependent: :destroy
  has_many :users, through: :user_notifications
  belongs_to :generator_user, class_name: 'User', optional: true

  enum type_of: Extends::NOTIFICATIONS_TYPES

  def already_seen(user)
    UserNotification.where(notification: self, user: user)
                    .pluck(:checked)
                    .first
  end
end
