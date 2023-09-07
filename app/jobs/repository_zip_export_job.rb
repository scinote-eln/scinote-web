# frozen_string_literal: true

class RepositoryZipExportJob < ZipExportJob
  private

  # Override
  def fill_content(dir, params)
    repository = Repository.find(params[:repository_id])
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
    data = RepositoryZipExport.to_csv(rows,
                                      params[:header_ids],
                                      @user,
                                      repository,
                                      nil,
                                      params[:my_module_id].present?)
    File.binwrite("#{dir}/export.csv", data)
  end
end
