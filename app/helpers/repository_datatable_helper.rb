module RepositoryDatatableHelper
  include InputSanitizeHelper
  def prepare_row_columns(repository_rows,
                          repository,
                          columns_mappings,
                          team,
                          assigned_rows)
    parsed_records = []
    repository_rows.each do |record|
      row = {
            'DT_RowId': record.id,
            '1': assigned_row(record, assigned_rows),
            '2': record.id,
            '3': escape_input(record.name),
            '4': I18n.l(record.created_at, format: :full),
            '5': escape_input(record.created_by.full_name),
            'recordEditUrl': Rails.application.routes.url_helpers
                                  .edit_repository_repository_row_path(
                                    repository,
                                    record.id
                                  ),
            'recordUpdateUrl': Rails.application.routes.url_helpers
                                    .repository_repository_row_path(
                                      repository,
                                      record.id
                                    ),
            'recordInfoUrl': Rails.application.routes.url_helpers
                                  .repository_row_path(record.id)
          }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          display_cell_value(cell, team)
      end
      parsed_records << row
    end
    parsed_records
  end

  def display_cell_value(cell, team)
    if cell.value_type == 'RepositoryAssetValue'
      render partial: 'shared/asset_link',
                      locals: { asset: cell.value.asset, display_image_tag: false },
                      formats: :html
    else
      custom_auto_link(display_tooltip(cell.value.data,
                                       Constants::NAME_MAX_LENGTH),
                       simple_format: true,
                       team: team)
    end
  end

  def assigned_row(record, assigned_rows)
    if assigned_rows&.include?(record)
      "<span class='circle'>&nbsp;</span>"
    else
      "<span class='circle disabled'>&nbsp;</span>"
    end
  end

  def can_perform_repository_actions(repository)
    team = repository.team
    can_manage_repository?(repository) ||
      can_create_repositories?(team) ||
      can_manage_repository_rows?(team)
  end

  # The order must be converted from Ruby Hash into a JS array -
  # because arrays in JS are in truth regular JS objects with indexes as keys
  def default_table_order_as_js_array
    Constants::REPOSITORY_TABLE_DEFAULT_STATE[:order].keys.sort.map do |k|
      Constants::REPOSITORY_TABLE_DEFAULT_STATE[:order][k]
    end.to_s
  end

  def default_table_columns
    Constants::REPOSITORY_TABLE_DEFAULT_STATE[:columns].keys.sort.map do |k|
      col = Constants::REPOSITORY_TABLE_DEFAULT_STATE[:columns][k]
      col.slice(:visible, :searchable)
    end.to_json
  end
end