# frozen_string_literal: true

require 'csv'

module RepositoryZipExport
  def self.generate_zip(params, repository, current_user)
    # Fetch rows in the same order as in the currently viewed datatable
    ordered_row_ids = params[:row_ids]
    id_row_map = RepositoryRow.where(id: ordered_row_ids,
                                     repository: repository)
                              .index_by(&:id)
    ordered_rows = ordered_row_ids.collect { |id| id_row_map[id.to_i] }

    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      to_csv(ordered_rows, params[:header_ids], current_user, repository.team),
      :repositories
    )
  end

  def self.to_csv(rows, column_ids, user, team, handle_file_name_func = nil)
    # Parse column names
    csv_header = []
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
                    else
                      column = RepositoryColumn.find_by_id(c_id)
                      column ? column.name : nil
                    end
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
                       row.id
                     when -4
                       row.name
                     when -5
                       row.created_by.full_name
                     when -6
                       I18n.l(row.created_at, format: :full)
                     else
                       cell = row.repository_cells
                                 .find_by(repository_column_id: c_id)

                       if cell
                         if cell.value_type == 'RepositoryAssetValue' &&
                            handle_file_name_func
                           handle_file_name_func.call(cell.value.asset)
                         else
                           SmartAnnotations::TagToText.new(
                             user, team, cell.value.export_formatted
                           ).text
                         end
                       end
                     end
        end
        csv << csv_row
      end
    end
  end
end
