# frozen_string_literal: true

class AddNotificationSentToRepositoryDateTimeValues < ActiveRecord::Migration[7.0]
  def change
    add_column :repository_date_time_values, :notification_sent, :boolean, default: false
  end
end
