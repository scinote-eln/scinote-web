# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_rows, repository, columns_mappings, team, options = {})
    repository_rows.map do |record|
      row = public_send("#{repository.class.name.underscore}_default_columns", record)

      row['DT_RowId'] = record.id
      row['DT_RowAttr'] = { 'data-state': row_style(record) }
      row['recordInfoUrl'] = Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)

      unless options[:view_mode]
        row['recordUpdateUrl'] =
          Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)
        row['recordEditable'] = record.editable?
      end

      row['0'] = record[:row_assigned] if options[:my_module]

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          display_cell_value(cell, team)
      end

      row
    end
  end

  def prepare_simple_view_row_columns(repository_rows)
    repository_rows.map do |record|
      {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        '0': escape_input(record.name),
        'recordInfoUrl': Rails.application.routes.url_helpers.repository_repository_row_path(record.repository, record)
      }
    end
  end

  def prepare_snapshot_row_columns(repository_rows, columns_mappings, team)
    repository_rows.map do |record|
      row = {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        '1': record.code,
        '2': escape_input(record.name),
        '3': I18n.l(record.created_at, format: :full),
        '4': escape_input(record.created_by.full_name),
        'recordInfoUrl': Rails.application.routes.url_helpers.repository_repository_row_path(record.repository, record)
      }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] = display_cell_value(cell, team)
      end

      row
    end
  end

  def assigned_row(record)
    {
      tasks: record.assigned_my_modules_count,
      experiments: record.assigned_experiments_count,
      projects: record.assigned_projects_count,
      task_list_url: assigned_task_list_repository_repository_row_path(record.repository, record)
    }
  end

  def can_perform_repository_actions(repository)
    can_read_repository?(repository) ||
      can_manage_repository?(repository) ||
      can_create_repositories?(repository.team) ||
      can_manage_repository_rows?(repository)
  end

  def repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': record.code,
      '3': escape_input(record.name),
      '4': I18n.l(record.created_at, format: :full),
      '5': escape_input(record.created_by.full_name),
      '6': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '7': escape_input(record.archived_by&.full_name)
    }
  end

  def linked_repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': escape_input(record.external_id),
      '3': record.code,
      '4': escape_input(record.name),
      '5': I18n.l(record.created_at, format: :full),
      '6': escape_input(record.created_by.full_name),
      '7': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '8': escape_input(record.archived_by&.full_name)
    }
  end

  def bmt_repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': escape_input(record.external_id),
      '3': record.code,
      '4': escape_input(record.name),
      '5': I18n.l(record.created_at, format: :full)
    }
  end

  def display_cell_value(cell, team)
    serializer_class = "RepositoryDatatable::#{cell.repository_column.data_type}Serializer".constantize
    serializer_class.new(
      cell.value,
      scope: { team: team, user: current_user, column: cell.repository_column }
    ).serializable_hash
  end

  def row_style(row)
    return I18n.t('general.archived') if row.archived

    ''
  end
end
