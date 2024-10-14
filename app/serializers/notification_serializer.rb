# frozen_string_literal: true

class NotificationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include BreadcrumbsHelper

  attributes :id, :title, :message, :created_at, :read_at, :type, :breadcrumbs, :checked, :today, :toggle_read_url

  def title
    object.to_notification.title
  end

  def breadcrumbs
    subject = object.to_notification.subject
    generate_breadcrumbs(subject, []) if subject
  end

  def message
    object.to_notification.message
  end

  def created_at
    I18n.l(object.created_at, format: :full)
  end

  def today
    object.created_at.today?
  end

  def checked
    object.read_at.present?
  end

  def toggle_read_url
    toggle_read_user_notification_path(object)
  end
end
