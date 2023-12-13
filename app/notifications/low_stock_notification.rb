# frozen_string_literal: true

class LowStockNotification < BaseNotification
  def self.subtype
    :item_low_stock_reminder
  end

  def title
    I18n.t(
      'notifications.content.item_low_stock_reminder.message_html',
      repository_row_name: subject.name,
      repository: repository.name
    )
  end

  def subject
    RepositoryRow.find(params[:repository_row_id])
  rescue ActiveRecord::RecordNotFound
    NonExistantRecord.new(params[:repository_row_name])
  end

  def repository
    Repository.find(params[:repository_id])
  rescue ActiveRecord::RecordNotFound
    NonExistantRecord.new(params[:repository_name])
  end
end
