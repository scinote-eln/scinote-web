# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_rows, repository, columns_mappings, team, options = {})
    repository_rows.map do |record|
      default_cells = {
        '1': assigned_row(record),
        '2': record.code,
        '3': escape_input(record.name),
        '4': I18n.l(record.created_at, format: :full),
        '5': escape_input(record.created_by.full_name),
        '6': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
        '7': escape_input(record.archived_by&.full_name)
      }

      row = {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        'recordInfoUrl': Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)
      }.merge(default_cells)

      if record.repository.has_stock_management?
        row['manageStockUrl'] = if record.has_stock?
                                  Rails.application.routes.url_helpers
                                       .edit_repository_stock_repository_repository_row_url(
                                         repository,
                                         record
                                       )
                                else
                                  Rails.application.routes.url_helpers
                                       .new_repository_stock_repository_repository_row_url(
                                         repository,
                                         record
                                       )
                                end
      end

      unless options[:view_mode]
        row['recordUpdateUrl'] =
          Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)
        row['recordEditable'] = record.editable?
      end

      row['0'] = record[:row_assigned] if options[:my_module]

      # Add custom columns
      custom_cells = record.repository_cells

      custom_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          display_cell_value(cell, team)
      end

      if options[:include_stock_consumption] && record.repository.has_stock_management? && options[:my_module]
        row[(default_cells.length + custom_cells.length + 1).to_s] =
          if record.repository_stock_cell.present?
            display_cell_value(record.repository_stock_cell, record.repository.team)
          end
        row[(default_cells.length + custom_cells.length + 2).to_s] = {
          stock_present: record.repository_stock_cell.present?,
          updateStockConsumptionUrl: Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
            options[:my_module],
            record.repository,
            row_id: record.id
          ),
          value: {
            consumed_stock_formatted: record.consumed_stock,
            unit: record.repository_stock_value.repository_stock_unit_item&.data
          }
        }
      end

      row
    end
  end

  def prepare_simple_view_row_columns(repository_rows, my_module, options = {})
    repository_rows.map do |record|
      row = {
        DT_RowId: record.id,
        DT_RowAttr: { 'data-state': row_style(record) },
        '0': escape_input(record.name),
        recordInfoUrl: Rails.application.routes.url_helpers.repository_repository_row_path(record.repository, record)
      }

      if options[:include_stock_consumption] && record.repository.has_stock_management?
        stock_present = record.repository_stock_cell.present?
        # Always disabled in a simple view
        stock_managable = false
        consumption_managable =
          stock_present && record.repository.is_a?(Repository) && can_update_my_module_stock_consumption?(my_module)

        row['1'] = stock_present ? display_cell_value(record.repository_stock_cell, record.repository.team) : {}
        row['1'][:stock_managable] = stock_managable
        row['2'] = {
          stock_present: stock_present,
          consumption_managable: consumption_managable
        }
        if record.repository.is_a?(RepositorySnapshot)
          if record.repository_stock_consumption_value.present?
            row['2'][:value] = {
              consumed_stock: record.repository_stock_consumption_value.amount,
              unit: record.repository_stock_consumption_value.repository_stock_unit_item&.data
            }
          end
        else
          if consumption_managable
            row['2'][:updateStockConsumptionUrl] =
              Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
                my_module, record.repository, row_id: record.id
              )
          end
          if record.consumed_stock.present?
            row['2'][:value] = {
              consumed_stock: record.consumed_stock,
              unit: record.repository_stock_value&.repository_stock_unit_item&.data
            }
          end
        end
      end

      row
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

  def default_table_order_as_js_array
    Constants::REPOSITORY_TABLE_DEFAULT_STATE['order'].to_json
  end

  def default_table_columns
    Constants::REPOSITORY_TABLE_DEFAULT_STATE['columns'].to_json
  end

  def default_snapshot_table_order_as_js_array
    Constants::REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE['order'].to_json
  end

  def default_snapshot_table_columns
    Constants::REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE['columns'].to_json
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
