# frozen_string_literal: true

class BaseNotification < Noticed::Base
  deliver_by :database, if: :database_notification?
  deliver_by :email, mailer: 'AppMailer', method: :general_notification, if: :email_notification?

  def self.send_notifications(params, later: true)
    recipients_class =
      "Recipients::#{NotificationExtends::NOTIFICATIONS_TYPES[subtype || params[:type]][:recipients_module]}".constantize
    recipients_class.new(params).recipients.each do |recipient|
      if later
        with(params).deliver_later(recipient)
      else
        with(params).deliver(recipient)
      end
    end
  end

  def self.subtype; end

  def subtype
    self.class.subtype || params[:type]
  end

  def subject; end

  def message
    params[:message]
  end

  def title
    params[:title]
  end

  private

  def database_notification?
    # always save all notifications,
    # but flag if they should display in app or not

    params[:hide_in_app] = recipient.notifications_settings.dig(notification_subgroup.to_s, 'in_app') != true

    true
  end

  def email_notification?
    recipient.notifications_settings.dig(notification_subgroup.to_s, 'email')
  end

  def notification_subgroup
    NotificationExtends::NOTIFICATIONS_GROUPS.values.reduce({}, :merge).find do |_sg, n|
      n.include?(subtype.to_sym)
    end[0]
  end
end
