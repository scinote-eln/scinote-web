# frozen_string_literal: true

class MigrateNotificationToNoticed < ActiveRecord::Migration[7.0]
  def up
    add_column :notifications, :params, :jsonb, default: {}, null: false
    add_column :notifications, :type, :string, null: false, default: 'LegacyNotification'
    add_column :notifications, :read_at, :datetime
    add_column :notifications, :recipient_id, :bigint
    add_column :notifications, :recipient_type, :string

    type_mapping = {
      'assignment' => 'ActivityNotification',
      'recent_changes' => 'GeneralNotification',
      'deliver' => 'DeliveryNotification',
      'deliver_error' => 'DeliveryNotification'
    }

    UserNotification.all.each do |user_notification|
      notification = user_notification.notification.dup

      new_type = type_mapping[notification.type_of]

      params = {
        title: notification.title,
        message: notification.message,
        legacy: true
      }

      params[:error] = notification.type_of == 'deliver_error' if new_type == 'DeliveryNotification'
      notification.update(
        params: params,
        type: new_type,
        read_at: (user_notification.updated_at if user_notification.checked),
        recipient_id: user_notification.user_id,
        recipient_type: 'User',
        created_at: user_notification.created_at,
        updated_at: user_notification.updated_at
      )
    end

    Notification.where(type: 'LegacyNotification').destroy_all

    remove_column :notifications, :type_of
    remove_column :notifications, :title
    remove_column :notifications, :message
    remove_column :notifications, :generator_user_id
  end
end
