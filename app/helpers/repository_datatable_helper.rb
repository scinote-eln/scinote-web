# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  def prepare_row_columns(repository_rows, repository, columns_mappings, team, options = {})
    has_stock_management = repository.has_stock_management?
    reminders_enabled = Repository.reminders_enabled?
    repository_rows = reminders_enabled ? with_reminders_status(repository_rows, repository) : repository_rows
    stock_managable = has_stock_management && !options[:disable_stock_management] &&
                      can_manage_repository_stock?(repository)
    stock_consumption_permitted = has_stock_management && options[:include_stock_consumption] && options[:my_module] &&
                                  stock_consumption_permitted?(repository, options[:my_module])

    repository_rows.map do |record|
      row = public_send("#{repository.class.name.underscore}_default_columns", record)
      row.merge!(
        DT_RowId: record.id,
        DT_RowAttr: { 'data-state': row_style(record), 'data-e2e': "e2e-TR-invInventory-bodyRow-#{record.id}" },
        recordInfoUrl: Rails.application.routes.url_helpers.repository_repository_row_path(repository, record),
        rowRemindersUrl:
          Rails.application.routes.url_helpers
               .active_reminder_repository_cells_repository_repository_row_url(
                 repository,
                 record
               ),
        relationshipsUrl:
          Rails.application.routes.url_helpers
               .relationships_repository_repository_row_url(record.repository_id, record.id),
        relationships_enabled: repository_row_connections_enabled,
        code: record.code
      )

      if reminders_enabled
        row['hasActiveReminders'] = record.has_active_stock_reminders || record.has_active_datetime_reminders
      end

      unless options[:view_mode]
        row['recordUpdateUrl'] =
          Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)
        row['recordEditable'] = record.editable?
      end

      row['0'] = record[:row_assigned] if options[:my_module]

      # Add custom columns
      custom_cells = record.repository_cells.filter { |cell| cell.value_type != 'RepositoryStockValue' }

      custom_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          serialize_repository_cell_value(cell, team, repository, reminders_enabled: reminders_enabled)
      end

      if repository.repository_columns.stock_type.exists?
        stock_cell = record.repository_cells.find { |cell| cell.value_type == 'RepositoryStockValue' }
        row['stock'] = serialize_repository_cell_value(record.repository_stock_cell, team, repository) if stock_cell.present?
      end

      if has_stock_management
        stock_cell = record.repository_cells.find { |cell| cell.value_type == 'RepositoryStockValue' }

        # always add stock cell, even if empty
        row['stock'] =
          if stock_cell.present?
            serialize_repository_cell_value(record.repository_stock_cell, team, repository)
          else
            { stock_url: new_repository_stock_repository_repository_row_url(repository, record) }
          end
        row['stock'][:stock_managable] = stock_managable && record.active?
        row['stock']['displayWarnings'] = display_stock_warnings?(repository)
        row['stock'][:stock_status] = stock_cell&.value&.status

        row['stock']['value_type'] = 'RepositoryStockValue'

        if options[:include_stock_consumption] && options[:my_module]
          consumption_managable = stock_consumption_managable?(record, repository, options[:my_module])
          consumed_stock_formatted =
            number_with_precision(
              record.consumed_stock,
              precision: (repository.repository_stock_column.metadata['decimals'].to_i || 0),
              strip_insignificant_zeros: true
            )
          row['consumedStock'] = {
            stock_present: stock_cell.present?,
            consumptionPermitted: stock_consumption_permitted,
            consumptionManagable: consumption_managable,
            updateStockConsumptionUrl: Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
              options[:my_module],
              repository,
              row_id: record.id
            ),
            value: {
              consumed_stock: record.consumed_stock,
              consumed_stock_formatted:
                "#{consumed_stock_formatted || 0} #{record.repository_stock_value&.repository_stock_unit_item&.data}"
            }
          }
        end
      end

      row
    end
  end

  def prepare_simple_view_row_columns(repository_rows, repository, my_module, options = {})
    has_stock_management = repository.has_stock_management?
    reminders_enabled = !options[:disable_reminders] && Repository.reminders_enabled?
    repository_rows = reminders_enabled ? with_reminders_status(repository_rows, repository) : repository_rows
    # Always disabled in a simple view
    stock_managable = false
    stock_consumption_permitted = has_stock_management && stock_consumption_permitted?(repository, my_module)

    repository_rows.map do |record|
      row = {
        DT_RowId: record.id,
        DT_RowAttr: { 'data-state': row_style(record) },
        '0': escape_input(record.name),
        recordInfoUrl: Rails.application.routes.url_helpers.repository_repository_row_path(record.repository, record),
        rowRemindersUrl:
          Rails.application.routes.url_helpers
               .active_reminder_repository_cells_repository_repository_row_url(
                 record.repository,
                 record
               )
      }

      if reminders_enabled
        row['hasActiveReminders'] = record.has_active_stock_reminders || record.has_active_datetime_reminders
      end

      if has_stock_management
        stock_present = record.repository_stock_cell.present?

        consumption_managable = stock_consumption_managable?(record, repository, my_module)

        row['stock'] =
          if stock_present
            serialize_repository_cell_value(record.repository_stock_cell, record.repository.team, repository)
          else
            {}
          end
        row['stock']['displayWarnings'] = display_stock_warnings?(repository)
        row['stock'][:stock_status] = record.repository_stock_cell&.value&.status

        row['stock'][:stock_managable] = stock_managable
        if record.repository.is_a?(RepositorySnapshot)
          row['consumedStock'] =
            if record.repository_stock_consumption_value.present?
              serialize_repository_cell_value(record.repository_stock_consumption_cell,
                                              record.repository.team,
                                              repository)
            else
              {}
            end
        else
          row['consumedStock'] = {}
          if consumption_managable
            row['consumedStock']['updateStockConsumptionUrl'] =
              Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
                my_module, record.repository, row_id: record.id
              )
          end
          consumed_stock_formatted =
            number_with_precision(
              record.consumed_stock,
              precision: (record.repository.repository_stock_column.metadata['decimals'].to_i || 0),
              strip_insignificant_zeros: true
            )
          row['consumedStock'][:value] = {
            consumed_stock: record.consumed_stock,
            consumed_stock_formatted:
              "#{consumed_stock_formatted || 0} #{record.repository_stock_value&.repository_stock_unit_item&.data}"
          }
        end

        row['consumedStock']['stock_present'] = stock_present
        row['consumedStock']['consumptionPermitted'] = stock_consumption_permitted
        row['consumedStock']['consumptionManagable'] = consumption_managable
      end

      row
    end
  end

  def prepare_snapshot_row_columns(repository_rows, columns_mappings, team, repository_snapshot, options = {})
    has_stock_management = repository_snapshot.has_stock_management?
    repository_rows.map do |record|
      row = {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        '1': record.code,
        '2': escape_input(record.name),
        '3': I18n.l(record.created_at, format: :full),
        '4': escape_input(record.created_by.full_name),
        'recordInfoUrl': Rails.application.routes.url_helpers
                              .repository_repository_row_path(repository_snapshot, record)
      }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          serialize_repository_cell_value(cell, team, repository_snapshot)
      end

      if has_stock_management
        row['stock'] = if record.repository_stock_cell.present?
                         serialize_repository_cell_value(record.repository_stock_cell, team, repository_snapshot)
                       else
                         { value_type: 'RepositoryStockValue' }
                       end

        row['consumedStock'] =
          if record.repository_stock_consumption_cell.present?
            serialize_repository_cell_value(record.repository_stock_consumption_cell, team, repository_snapshot)
          else
            {}
          end
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

  def repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': record.code,
      '3': escape_input(record.name),
      '4': "#{record.parent_connections_count || 0} / #{record.child_connections_count || 0}",
      '5': I18n.l(record.created_at, format: :full),
      '6': escape_input(record.created_by.full_name),
      '7': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '8': escape_input(record.archived_by&.full_name)
    }
  end

  def linked_repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': record.code,
      '3': escape_input(record.name),
      '4': I18n.l(record.created_at, format: :full),
      '5': escape_input(record.created_by.full_name),
      '6': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '7': escape_input(record.archived_by&.full_name),
      '8': escape_input(record.external_id)
    }
  end

  def serialize_repository_cell_value(cell, team, repository, options = {})
    serializer_class = "RepositoryDatatable::#{cell.repository_column.data_type}Serializer".constantize
    serializer_class.new(
      cell.value,
      scope: {
        team: team,
        user: current_user,
        column: cell.repository_column,
        repository: repository,
        options: options
      }
    ).serializable_hash
  end

  def row_style(row)
    return I18n.t('general.archived') if row.archived

    ''
  end

  def with_reminders_status(repository_rows, repository)
    # don't load reminders for archived repositories or snapshots
    if repository.archived? || repository.is_a?(RepositorySnapshot)
      return repository_rows.select('FALSE AS has_active_stock_reminders')
                            .select('FALSE AS has_active_datetime_reminders')
    end

    repository_cells = RepositoryCell.joins(
      "INNER JOIN repository_columns ON repository_columns.id = repository_cells.repository_column_id " \
      "AND repository_columns.repository_id = #{repository.id}"
    )

    repository_rows
      .joins(
        "LEFT OUTER JOIN (#{RepositoryCell.stock_reminder_repository_cells_scope(repository_cells, current_user)
                                          .select(:id, :repository_row_id).to_sql}) " \
        "AS repository_cells_with_active_stock_reminders " \
        "ON repository_cells_with_active_stock_reminders.repository_row_id = repository_rows.id"
      )
      .joins(
        "LEFT OUTER JOIN (#{RepositoryCell.date_time_reminder_repository_cells_scope(repository_cells, current_user)
                                          .select(:id, :repository_row_id).to_sql}) " \
        "AS repository_cells_with_active_datetime_reminders " \
        "ON repository_cells_with_active_datetime_reminders.repository_row_id = repository_rows.id"
      )
      .select('COUNT(repository_cells_with_active_stock_reminders.id) > 0 AS has_active_stock_reminders')
      .select('COUNT(repository_cells_with_active_datetime_reminders.id) > 0 AS has_active_datetime_reminders')
  end

  def stock_consumption_permitted?(repository, my_module)
    return false unless repository.is_a?(Repository) && current_user

    can_update_my_module_stock_consumption?(my_module)
  end

  def stock_consumption_managable?(record, repository, my_module)
    return false unless my_module
    return false if repository.archived? || record.archived?

    true
  end

  def display_stock_warnings?(repository)
    !repository.is_a?(RepositorySnapshot)
  end

  def repository_row_connections_enabled
    Repository.repository_row_connections_enabled?
  end
end
