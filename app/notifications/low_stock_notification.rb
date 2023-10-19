# frozen_string_literal: true

class LowStockNotification < BaseNotification
  def message
    I18n.t(
      'notifications.notification.item_low_stock_reminder_html',
      repository_row_name: subject.name
    )
  end

  def self.subtype
    :item_low_stock_reminder
  end

  def title; end

  def subject
    RepositoryRow.find(params[:repository_row_id])
  end
end
