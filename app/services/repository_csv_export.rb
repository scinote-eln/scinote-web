# frozen_string_literal: true

require 'csv'

module RepositoryCsvExport
  def self.to_csv(rows, column_ids, user, repository, handle_file_name_func, in_module, empty_export)
    # Parse column names
    csv_header = []
    add_consumption = in_module && !repository.is_a?(RepositorySnapshot) && repository.has_stock_management?
    column_ids.each do |c_id|
      case c_id
      when -1, -2
        next
      when -3
        csv_header << I18n.t('repositories.table.id')
      when -4
        csv_header << I18n.t('repositories.table.row_name')
      when -5
        csv_header << I18n.t('repositories.table.added_by')
      when -6
        csv_header << I18n.t('repositories.table.added_on')
      when -7
        csv_header << I18n.t('repositories.table.updated_on')
      when -8
        csv_header << I18n.t('repositories.table.updated_by')
      when -9
        csv_header << I18n.t('repositories.table.archived_by')
      when -10
        csv_header << I18n.t('repositories.table.archived_on')
      when -11
        csv_header << I18n.t('repositories.table.parents')
        csv_header << I18n.t('repositories.table.children')
      else
        csv_header << repository.repository_columns.find_by(id: c_id)&.name
      end
    end
    csv_header << I18n.t('repositories.table.row_consumption') if add_consumption

    CSV.generate do |csv|
      csv << csv_header
      unless empty_export
        rows.each do |row|
          csv_row = []
          column_ids.each do |c_id|
            case c_id
            when -1, -2
              next
            when -3
              csv_row << (repository.is_a?(RepositorySnapshot) ? row.parent_id : row.code)
            when -4
              csv_row << row.name
            when -5
              csv_row << row.created_by.full_name
            when -6
              csv_row << I18n.l(row.created_at, format: :full)
            when -7
              csv_row << row.updated_at ? I18n.l(row.updated_at, format: :full) : ''
            when -8
              csv_row << row.last_modified_by.full_name
            when -9
              csv_row << (row.archived? && row.archived_by.present? ? row.archived_by.full_name : '')
            when -10
              csv_row << (row.archived? && row.archived_on.present? ? I18n.l(row.archived_on, format: :full) : '')
            when -11
              csv_row << row.parent_repository_rows.map(&:code).join(' | ')
              csv_row << row.child_repository_rows.map(&:code).join(' | ')
            else
              cell = row.repository_cells.find_by(repository_column_id: c_id)

            csv_row << if cell
                        if cell.value_type == 'RepositoryAssetValue' && handle_file_name_func
                          handle_file_name_func.call(cell.value.asset)
                        else
                          cell.value.export_formatted
                        end
                       end
            end
          end
          csv_row << row.row_consumption(row.stock_consumption) if add_consumption
          csv << csv_row
        end
      end
    end.encode('UTF-8', invalid: :replace, undef: :replace)
  end
end
