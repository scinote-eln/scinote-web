# frozen_string_literal: true

class LowStockNotification < BaseNotification
  def message
    I18n.t(
      'notifications.content.item_low_stock_reminder.message_html',
      repository_row_name: subject.name,
      repository: repository.name
    )
  end

  def self.subtype
    :item_low_stock_reminder
  end

  def title
    I18n.t('notifications.content.item_low_stock_reminder.title_html')
  end

  def subject
    RepositoryRow.find(params[:repository_row_id])
  end

  def repository
    Repository.find(subject.repository_id)
  end
end
