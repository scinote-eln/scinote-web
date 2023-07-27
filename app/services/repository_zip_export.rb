# frozen_string_literal: true

require 'csv'

module RepositoryZipExport
  def self.generate_zip(params, repository, current_user)
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

    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      to_csv(rows, params[:header_ids], current_user, repository, nil, params[:my_module_id].present?),
      :repositories
    )
  end

  def self.to_csv(rows, column_ids, user, repository, handle_file_name_func = nil, in_module = false)
    # Parse column names
    csv_header = []
    add_consumption = in_module && !repository.is_a?(RepositorySnapshot) && repository.has_stock_management?
    column_ids.each do |c_id|
      csv_header << case c_id.to_i
                    when -1, -2
                      next
                    when -3
                      I18n.t('repositories.table.id')
                    when -4
                      I18n.t('repositories.table.row_name')
                    when -5
                      I18n.t('repositories.table.added_by')
                    when -6
                      I18n.t('repositories.table.added_on')
                    when -7
                      I18n.t('repositories.table.archived_by')
                    when -8
                      I18n.t('repositories.table.archived_on')
                    else
                      column = repository.repository_columns.find_by(id: c_id)
                      column ? column.name : nil
                    end
    end
    csv_header << I18n.t('repositories.table.row_consumption') if add_consumption

    CSV.generate do |csv|
      csv << csv_header
      rows.each do |row|
        csv_row = []
        column_ids.each do |c_id|
          csv_row << case c_id.to_i
                     when -1, -2
                       next
                     when -3
                       repository.is_a?(RepositorySnapshot) ? row.parent_id : row.id
                     when -4
                       row.name
                     when -5
                       row.created_by.full_name
                     when -6
                       I18n.l(row.created_at, format: :full)
                     when -7
                       row.archived? && row.archived_by.present? ? row.archived_by.full_name : ''
                     when -8
                       row.archived? && row.archived_on.present? ? I18n.l(row.archived_on, format: :full) : ''
                     else
                       cell = row.repository_cells.find_by(repository_column_id: c_id)

                       if cell
                         if cell.value_type == 'RepositoryAssetValue' && handle_file_name_func
                           handle_file_name_func.call(cell.value.asset)
                         else
                           SmartAnnotations::TagToText.new(
                             user, repository.team, cell.value.export_formatted
                           ).text
                         end
                       end
                     end
        end

        csv_row << row.row_consumption(row.stock_consumption) if add_consumption
        csv << csv_row
      end
    end
  end
end
