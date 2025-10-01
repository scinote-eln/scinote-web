# frozen_string_literal: true

class RepositoryZipExportJob < ZipExportJob
  private

  # Override
  def fill_content(dir, params)
    repository = RepositoryBase.find(params[:repository_id])
    col_ids = params[:header_ids].map(&:to_i)
    # Storage locations column is always added if they have enabled feature
    col_ids << -12 if StorageLocation.storage_locations_enabled?
    # Fetch rows in the same order as in the currently viewed datatable
    if params[:my_module_id]
      rows = if repository.is_a?(RepositorySnapshot)
               repository.repository_rows
             else
               repository.repository_rows
                         .joins(:my_module_repository_rows)
                         .where(my_module_repository_rows: { my_module_id: params[:my_module_id] })
             end
      if repository.has_stock_management?
        rows = rows.left_joins(my_module_repository_rows: :repository_stock_unit_item)
                   .select(
                     'repository_rows.*',
                     'my_module_repository_rows.stock_consumption'
                   )
      end
      service = RepositoryExportService.new(@file_type, rows, col_ids,
                                            repository, in_module: true)
    else
      ordered_row_ids = params[:row_ids].map(&:to_i)
      rows = repository.repository_rows.where(id: ordered_row_ids)
      service = RepositoryExportService.new(@file_type, rows, col_ids,
                                            repository, in_module: false, ordered_row_ids: ordered_row_ids)
    end
    exported_data = service.export!
    File.binwrite("#{dir}/export.#{@file_type}", exported_data)
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.repository_item'))
  end
end
