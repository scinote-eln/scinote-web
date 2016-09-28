class Notification < ActiveRecord::Base
  has_many :user_notifications, inverse_of: :notification
  has_many :users, through: :user_notifications
end
