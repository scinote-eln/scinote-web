# frozen_string_literal: true

require 'csv'

module RepositoryZipExport
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
                    when 'relationship'
                      next
                    else
                      column = repository.repository_columns.find_by(id: c_id)
                      column ? column.name : nil
                    end
    end
    csv_header << I18n.t('repositories.table.row_consumption') if add_consumption

    if column_ids.include? 'relationship'
      csv_header << I18n.t('repositories.table.parents')
      csv_header << I18n.t('repositories.table.children')
    end

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
                     when 'relationship'
                       next
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
        if column_ids.include? 'relationship'
          csv_row << "\"#{row.parent_repository_rows.map(&:code).join("\;\s")}\""
          csv_row << "\"#{row.child_repository_rows.map(&:code).join("\;\s")}\""
        end

        csv << csv_row
      end
    end
  end
end
