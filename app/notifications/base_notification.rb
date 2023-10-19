# frozen_string_literal: true

class BaseNotification < Noticed::Base
  deliver_by :database, if: :database_notification?

  def self.send_notifications(params, later: false)
    recipients_class =
      "Recipients::#{NotificationExtends::NOTIFICATIONS_TYPES[subtype][:recipients_module]}".constantize
    recipients_class.new(params).recipients.each do |recipient|
      if later
        with(params).deliver_later(recipient)
      else
        with(params).deliver(recipient)
      end
    end
  end

  def self.subtype
    params[:type]
  end

  def subject; end

  private

  def database_notification?
    recipient.notifications_settings.dig(notification_subgroup.to_s, 'in_app')
  end

  def notification_subgroup
    NotificationExtends::NOTIFICATIONS_GROUPS.values.reduce({}, :merge).find do |_sg, n|
      n.include?(self.class.subtype.to_sym)
    end[0]
  end
end
