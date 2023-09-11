# frozen_string_literal: true

class RepositoryStockZipExportJob < ZipExportJob
  private

  # Overrride
  def fill_content(dir, params)
    data = RepositoryStockLedgerZipExport.to_csv(params[:repository_row_ids])
    File.binwrite("#{dir}/export.csv", data)
  end
end
