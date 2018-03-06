module RepositoryDatatableHelper
  include InputSanitizeHelper
  def prepare_row_columns(repository_rows, repository, columns_mappings, team)
    parsed_records = []
    repository_rows.each do |record|
      row = {
            'DT_RowId': record.id,
            '1': assigned_row(record),
            '2': escape_input(record.name),
            '3': I18n.l(record.created_at, format: :full),
            '4': escape_input(record.created_by.full_name),
            'recordEditUrl':
              Rails.application.routes.url_helpers
                   .edit_repository_repository_row_path(repository,
                                                        record.id),
            'recordUpdateUrl':
              Rails.application.routes.url_helpers
                   .repository_repository_row_path(repository, record.id),
            'recordInfoUrl':
              Rails.application.routes.url_helpers.repository_row_path(record.id)
          }

      # Add custom columns
      # byebug
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          custom_auto_link(
            display_tooltip(cell.value.data,
                            Constants::NAME_MAX_LENGTH),
            simple_format: true,
            team: team
          )
      end
      parsed_records << row
    end
    parsed_records
  end

  def assigned_row(record)
    # if @assigned_rows && @assigned_rows.include?(record)
    #   "<span class='circle'>&nbsp;</span>"
    # else
    "<span class='circle disabled'>&nbsp;</span>"
    # end
  end
end
