# frozen_string_literal: true

class RepositoryStockZipExportJob < ZipExportJob
  private

  # Overrride
  def fill_content(dir, params)
    data = RepositoryStockLedgerZipExport.to_csv(params[:repository_row_ids])
    File.binwrite("#{dir}/export.csv", data)
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.stock_consumption'))
  end
end
