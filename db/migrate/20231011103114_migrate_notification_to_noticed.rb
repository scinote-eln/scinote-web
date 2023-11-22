# frozen_string_literal: true

class MigrateNotificationToNoticed < ActiveRecord::Migration[7.0]
  class UserNotification < ApplicationRecord
    belongs_to :notification
  end

  def up
    add_column :notifications, :params, :jsonb, default: {}, null: false
    add_column :notifications, :type, :string
    add_column :notifications, :read_at, :datetime
    add_reference :notifications, :recipient, polymorphic: true

    Notification.reset_column_information

    type_mapping = {
      0 => 'ActivityNotification',
      1 => 'GeneralNotification',
      5 => 'DeliveryNotification',
      7 => 'DeliveryNotification'
    }
    UserNotification.where('created_at > ?', 3.months.ago).includes(:notification).find_each do |user_notification|
      notification = user_notification.notification

      new_type = type_mapping[notification.type_of]
      new_type ||= 'GeneralNotification'

      params = {
        title: notification.title,
        message: notification.message,
        legacy: true
      }

      params[:error] = notification.type_of == 7 if new_type == 'DeliveryNotification'
      Notification.create!(
        params: params,
        type: new_type,
        type_of: notification.type_of,
        read_at: (user_notification.updated_at if user_notification.checked),
        recipient_id: user_notification.user_id,
        recipient_type: 'User',
        created_at: user_notification.created_at,
        updated_at: user_notification.updated_at
      )
    end

    UserNotification.delete_all
    Notification.where(type: nil).delete_all

    drop_table :user_notifications
    change_column_null :notifications, :type, false

    remove_column :notifications, :type_of
    remove_column :notifications, :title
    remove_column :notifications, :message
    remove_column :notifications, :generator_user_id
  end
end
