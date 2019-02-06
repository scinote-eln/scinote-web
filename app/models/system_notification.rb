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

  has_many :user_system_notifications
  has_many :users, through: :user_system_notifications

  validates :title, :modal_title, :modal_body, :description,
            :source_created_at, :source_id, :last_time_changed_at,
            presence: true

  def self.last_notifications(
    user,
    query = nil
  )
    notificaitons = order(last_time_changed_at: :DESC)
    notificaitons = notificaitons.search_notifications(query) if query && !query.empty?
    notificaitons.joins(:user_system_notifications)
                 .where('user_system_notifications.user_id = ?', user.id)
                 .select(
                   'system_notifications.id',
                   :title,
                   :description,
                   :last_time_changed_at,
                   'user_system_notifications.seen_at'
                 )
  end
end
