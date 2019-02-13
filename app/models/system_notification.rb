# frozen_string_literal: true

class SystemNotification < ApplicationRecord
  include PgSearch
  # Full text postgreSQL search configuration
  pg_search_scope :search_notifications, against: %i(title description),
                                           using: {
                                             tsearch: {
                                               dictionary: 'english'
                                             }
                                           }
  #  ignoring: :accents

  has_many :user_system_notifications
  has_many :users, through: :user_system_notifications

  validates :title, :modal_title, :modal_body, :description,
            :source_created_at, :source_id, :last_time_changed_at,
            presence: true

  validates :title, :description,
            length: { maximum: Constants::NAME_MAX_LENGTH }

  def self.last_notifications(
    user,
    query = nil
  )
    notifications = order(last_time_changed_at: :DESC)
    notifications = notifications.search_notifications(query) if query.present?
    notifications.joins(:user_system_notifications)
                 .where('user_system_notifications.user_id = ?', user.id)
                 .select(
                   'system_notifications.id',
                   :title,
                   :description,
                   :last_time_changed_at,
                   'user_system_notifications.seen_at'
                 )
  end

  def self.last_sync_timestamp
    # If no notifications are present, the created_at of the
    # first user is used as the "initial sync time-point"
    SystemNotification
      .order(last_time_changed_at: :desc)
      .first&.last_time_changed_at&.to_i ||
      User.order(created_at: :desc).first&.created_at&.to_i
  end
end
