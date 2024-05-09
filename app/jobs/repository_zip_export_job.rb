# frozen_string_literal: true

class RepositoryZipExportJob < ZipExportJob
  private

  # Override
  def fill_content(dir, params)
    repository = RepositoryBase.find(params[:repository_id])
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
    else
      ordered_row_ids = params[:row_ids]
      id_row_map = RepositoryRow.where(id: ordered_row_ids,
                                       repository: repository)
                                .index_by(&:id)
      rows = ordered_row_ids.collect { |id| id_row_map[id.to_i] }
    end
    service = RepositoryExportService
              .new(@file_type,
                   rows,
                   params[:header_ids].map(&:to_i),
                   @user,
                   repository,
                   in_module: params[:my_module_id].present?,
                   empty_export: @empty_export)
    exported_data = service.export!

    if @empty_export
      File.binwrite("#{dir}/Export_Inventory_Empty_#{Time.now.utc.strftime('%F %H-%M-%S_UTC')}.#{@file_type}", exported_data)
    else
      File.binwrite("#{dir}/export.#{@file_type}", exported_data)
    end
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.repository_item'))
  end
end
