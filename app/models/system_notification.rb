# frozen_string_literal: true

class SystemNotification < ApplicationRecord
  has_many :user_system_notifications
  has_many :users, through: :user_system_notifications

  validates :title, :modal_title, :modal_body, :description,
            :source_created_at, :source_id,
            presence: true
end
