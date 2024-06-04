# frozen_string_literal: true

require 'caxlsx'

module RepositoryXlsxExport
  def self.to_empty_xlsx(repository, column_ids)
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.add_worksheet(name: 'Data Export') do |sheet|
      sheet.add_row prepare_header(repository, column_ids, false)
    end

    package.to_stream.read
  end

  def self.to_xlsx(rows, column_ids, user, repository, handle_file_name_func, in_module)
    package = Axlsx::Package.new
    workbook = package.workbook
    add_consumption = in_module && !repository.is_a?(RepositorySnapshot) && repository.has_stock_management?

    workbook.add_worksheet(name: 'Data Export') do |sheet|
      sheet.add_row prepare_header(repository, column_ids, add_consumption)

      rows.each do |row|
        row_data = []
        column_ids.each do |c_id|
          case c_id
          when -1, -2
            next
          when -3
            row_data << (repository.is_a?(RepositorySnapshot) ? row.parent_id : row.id)
          when -4
            row_data << row.name
          when -5
            row_data << row.created_by.full_name
          when -6
            row_data << I18n.l(row.created_at, format: :full)
          when -7
            csv_row << row.updated_at ? I18n.l(row.updated_at, format: :full) : ''
          when -8
            csv_row << row.last_modified_by.full_name
          when -9
            row_data << (row.archived? && row.archived_by.present? ? row.archived_by.full_name : '')
          when -10
            row_data << (row.archived? && row.archived_on.present? ? I18n.l(row.archived_on, format: :full) : '')
          when -11
            row_data << row.parent_repository_rows.map(&:code).join(' | ')
            row_data << row.child_repository_rows.map(&:code).join(' | ')
          else
            cell = row.repository_cells.find_by(repository_column_id: c_id)

            row_data << if cell
                          if cell.value_type == 'RepositoryAssetValue' && handle_file_name_func
                            handle_file_name_func.call(cell.value.asset)
                          else
                            cell.value.export_formatted
                          end
                        end
          end
        end
        row_data << row.row_consumption(row.stock_consumption) if add_consumption
        sheet.add_row row_data
      end
    end

    package.to_stream.read
  end

  private

  def self.prepare_header(repository, column_ids, add_consumption)
    header = []
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
        header << repository.repository_columns.find_by(id: c_id)&.name
      end
    end
    header << I18n.t('repositories.table.row_consumption') if add_consumption

    header
  end
end
