# frozen_string_literal: true

require 'csv'

class RepositoryCsvExport
  def self.to_csv(rows, column_ids, repository, handle_file_name_func, in_module, ordered_row_ids = nil)
    add_consumption = in_module && !repository.is_a?(RepositorySnapshot) && repository.has_stock_management?
    csv_header = build_header(repository, column_ids, add_consumption)

    CSV.generate do |csv|
      csv << csv_header

      rows = rows.preload(:parent) if repository.is_a?(RepositorySnapshot)
      rows = rows.left_outer_joins(:created_by, :last_modified_by, :archived_by)
                 .joins('LEFT OUTER JOIN "users" "created_by" ON "created_by"."id" = "repository_rows"."created_by_id"')
                 .joins('LEFT OUTER JOIN "users" "last_modified_by" ON "last_modified_by"."id" = "repository_rows"."last_modified_by_id"')
                 .joins('LEFT OUTER JOIN "users" "archived_by" ON "archived_by"."id" = "repository_rows"."archived_by_id"')
                 .preload(:parent_repository_rows,
                          :child_repository_rows,
                          repository_cells: { repository_column: nil, value: repository.cell_preload_includes })
                 .select('repository_rows.* AS repository_rows')
                 .select('created_by.full_name AS created_by_full_name')
                 .select('last_modified_by.full_name AS last_modified_by_full_name')
                 .select('archived_by.full_name AS archived_by_full_name')

      if ordered_row_ids.present?
        rows = rows.order(RepositoryRow.sanitize_sql_for_order([Arel.sql('array_position(ARRAY[?], repository_rows.id)'), ordered_row_ids]))
        rows.each do |row|
          csv << build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
        end
      else
        rows.find_each(batch_size: 100) do |row|
          csv << build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
        end
      end
    end.encode('UTF-8', invalid: :replace, undef: :replace)
  end

  class << self
    private

    def build_header(repository, column_ids, add_consumption)
      # Parse column names
      csv_header = []
      custom_columns = repository.repository_columns.select(:id, :name)
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
          csv_header << custom_columns.find { |column| column.id == c_id }&.name
        end
      end
      csv_header << I18n.t('repositories.table.row_consumption') if add_consumption
      csv_header
    end

    def build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
      csv_row = []
      column_ids.each do |c_id|
        case c_id
        when -1, -2
          next
        when -3
          csv_row << row.code
        when -4
          csv_row << row.name
        when -5
          csv_row << row.created_by_full_name
        when -6
          csv_row << I18n.l(row.created_at, format: :full)
        when -7
          csv_row << (row.updated_at ? I18n.l(row.updated_at, format: :full) : '')
        when -8
          csv_row << row.last_modified_by_full_name
        when -9
          csv_row << (row.archived? && row.archived_by.present? ? row.archived_by_full_name : '')
        when -10
          csv_row << (row.archived? && row.archived_on.present? ? I18n.l(row.archived_on, format: :full) : '')
        when -11
          csv_row << row.parent_repository_rows.map(&:code).join(' | ')
          csv_row << row.child_repository_rows.map(&:code).join(' | ')
        else
          cell = row.repository_cells.find { |c| c.repository_column_id == c_id }
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
      csv_row
    end
  end
end
