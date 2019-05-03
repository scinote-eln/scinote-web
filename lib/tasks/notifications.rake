# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :notifications do
  desc 'Copies system notifications to newly created data structure.' \
       'IT SHOULD BE RUN ONE TIME ONLY'
  task copy_system_notifications: :environment do
    t0 = Time.now
    system_notifications = Notification
                           .where(type_of: :system_message)
                           .where(generator_user_id: nil)
                           .where.not('title like ?', 'Congratulations%')

    system_notifications.each do |system_notification|
      new_notification = SystemNotification.create!(
        source_id: -1,
        title: system_notification.title,
        description: system_notification.message,
        modal_title: system_notification.title,
        modal_body: system_notification.message,
        show_on_login: false,
        source_created_at: system_notification.created_at,
        last_time_changed_at: system_notification.created_at
      )

      created_at = system_notification.created_at

      sql = ' INSERT INTO user_system_notifications
          (
            user_id,
            created_at,
            updated_at,
            system_notification_id,
            seen_at,
            read_at
          )
          VALUES
        '
      user_notifications = UserNotification
                           .where(notification_id: system_notification.id)
      values_array = user_notifications.map do |user_notification|
        user_notification
          .slice(:user_id, :created_at, :updated_at)
          .merge(system_notification_id: new_notification.id)
          .merge(seen_at: created_at, read_at: created_at)
          .values
          .map { |v| "'#{v}'" }
          .join(',')
      end

      values_sql = values_array
                   .map { |v| "(#{v})" }
                   .join(',')

      sql += values_sql
      ActiveRecord::Base.connection.execute(sql)
    end

    t1 = Time.now
    puts "Task took #{t1 - t0}"
  end

  desc 'Removes obsolete system notifications from notifications table.'
  task delete_obsolete_system_notifications: :environment do
    system_notifications = Notification
                           .where(type_of: :system_message)
                           .where(generator_user_id: nil)
                           .where.not('title like ?', 'Congratulations%')
    UserNotification
      .where(notification_id: system_notifications.pluck(:id))
      .delete_all

    system_notifications.delete_all
  end
end
# rubocop:enable Metrics/BlockLength
