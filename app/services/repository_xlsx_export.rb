# frozen_string_literal: true

require 'caxlsx'

class RepositoryXlsxExport
  def self.to_empty_xlsx(repository, column_ids)
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Data Export') do |sheet|
      sheet.add_row build_header(repository, column_ids, false)
    end

    add_instruction(workbook)

    package.to_stream.read
  end

  def self.to_xlsx(rows, column_ids, repository, handle_file_name_func, in_module, ordered_row_ids = nil)
    package = Axlsx::Package.new
    workbook = package.workbook
    datetime_style = workbook.styles.add_style format_code: 'dd-mmm-yyyy hh:mm:ss'
    date_style = workbook.styles.add_style format_code: 'dd-mmm-yyyy'

    add_consumption = in_module && !repository.is_a?(RepositorySnapshot) && repository.has_stock_management?

    workbook.add_worksheet(name: 'Data Export') do |sheet|
      sheet.add_row build_header(repository, column_ids, add_consumption)

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
          row_data = build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
          sheet.add_row(row_data, style: build_row_style(row_data, datetime_style, date_style))
        end
      else
        rows.find_each(batch_size: 100) do |row|
          row_data = build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
          sheet.add_row(row_data, style: build_row_style(row_data, datetime_style, date_style))
        end
      end
    end

    add_instruction(workbook)

    package.to_stream.read
  end

  class << self
    private

    def add_instruction(workbook)
      workbook.add_worksheet(name: 'Instruction') do |sheet|
        image = File.expand_path('app/assets/images/import_instruction.png')
        sheet.add_image(image_src: image, start_at: 'A1', width: 1260, height: 994)
      end
    end

    def build_header(repository, column_ids, add_consumption)
      header = []
      custom_columns = repository.repository_columns.select(:id, :name)
      column_ids.each do |c_id|
        case c_id
        when -1, -2
          next
        when -3
          header << I18n.t('repositories.table.id')
        when -4
          header << I18n.t('repositories.table.row_name')
        when -5
          header << I18n.t('repositories.table.added_by')
        when -6
          header << I18n.t('repositories.table.added_on')
        when -7
          header << I18n.t('repositories.table.updated_on')
        when -8
          header << I18n.t('repositories.table.updated_by')
        when -9
          header << I18n.t('repositories.table.archived_by')
        when -10
          header << I18n.t('repositories.table.archived_on')
        when -11
          header << I18n.t('repositories.table.parents')
          header << I18n.t('repositories.table.children')
        else
          header << custom_columns.find { |column| column.id == c_id }&.name
        end
      end
      header << I18n.t('repositories.table.row_consumption') if add_consumption
      header
    end

    def build_row(row, column_ids, repository, handle_file_name_func, add_consumption)
      row_data = []
      column_ids.each do |c_id|
        case c_id
        when -1, -2
          next
        when -3
          row_data << row.code
        when -4
          row_data << row.name
        when -5
          row_data << row.created_by_full_name
        when -6
          row_data << row.created_at
        when -7
          row_data << row.updated_at
        when -8
          row_data << row.last_modified_by_full_name
        when -9
          row_data << (row.archived? && row.archived_by.present? ? row.archived_by_full_name : '')
        when -10
          row_data << row.archived_on
        when -11
          row_data << row.parent_repository_rows.map(&:code).join(' | ')
          row_data << row.child_repository_rows.map(&:code).join(' | ')
        else
          cell = row.repository_cells.find { |c| c.repository_column_id == c_id }
          row_data << if cell
                        if cell.value_type == 'RepositoryAssetValue' && handle_file_name_func
                          handle_file_name_func.call(cell.value.asset)
                        elsif cell.value.is_a?(RepositoryDateTimeValue) || cell.value.is_a?(RepositoryDateValue)
                          cell.value.data
                        else
                          cell.value.export_formatted
                        end
                      end
        end
      end
      row_data << row.row_consumption(row.stock_consumption) if add_consumption
      row_data
    end

    def build_row_style(row_data, datetime_style, date_style)
      row_data.map do |c|
        case c
        when ActiveSupport::TimeWithZone
          datetime_style
        when Time # Date values are of class Time for some reason
          date_style
        end
      end
    end
  end
end
