# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_rows,
                          repository,
                          columns_mappings,
                          team)
    parsed_records = []
    includes_json = { repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES }

    repository_rows.includes(:repository_columns, :created_by, includes_json).each do |record|
      row = {
        'DT_RowId': record.id,
        '1': assigned_row(record),
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

  def assigned_row(record)
    if record.assigned_my_modules_count.positive?
      "<span class='circle-icon'>&nbsp;</span>"
    else
      "<span class='circle-icon disabled'>&nbsp;</span>"
    end
  end

  def can_perform_repository_actions(repository)
    can_read_repository?(repository) ||
      can_manage_repository?(repository) ||
      can_create_repositories?(repository.team) ||
      can_manage_repository_rows?(repository)
  end

  def default_table_order_as_js_array
    Constants::REPOSITORY_TABLE_DEFAULT_STATE['order'].to_json
  end

  def default_table_columns
    Constants::REPOSITORY_TABLE_DEFAULT_STATE['columns'].to_json
  end

  def display_cell_value(cell, team)
    value_name = cell.repository_column.data_type.underscore
    serializer_class = "RepositoryDatatable::#{cell.repository_column.data_type}Serializer".constantize
    serializer_class.new(
      cell.__send__(value_name),
      scope: { team: team, user: current_user, column: cell.repository_column }
    ).serializable_hash
  end
end
