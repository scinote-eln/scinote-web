# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  def prepare_row_columns(repository_rows, repository, columns_mappings, team, options = {})
    # repository_rows collection is already preloaded in controllers, do not modify scopes or query params
    # otherwise it will result in duplicated SQL queries
    has_stock_management = repository.has_stock_management?
    stock_management_column_exists = repository.repository_columns.stock_type.exists?
    repository_row_connections_enabled = Repository.repository_row_connections_enabled?
    reminders_enabled = Repository.reminders_enabled?
    stock_managable = has_stock_management && !options[:disable_stock_management] &&
                      can_manage_repository_stock?(repository)
    stock_consumption_permitted = has_stock_management && options[:include_stock_consumption] && options[:my_module] &&
                                  stock_consumption_permitted?(repository, options[:my_module])
    default_columns_method_name = "#{repository.class.name.underscore}_default_columns"

    repository_rows.map do |record|
      row = public_send(default_columns_method_name, record)
      row['code'] = record.code
      row['DT_RowId'] = record.id
      row['DT_RowAttr'] = { 'data-state': row_style(record), 'data-e2e': "e2e-TR-invInventory-bodyRow-#{record.id}" }
      row['recordInfoUrl'] = Rails.application.routes.url_helpers.repository_repository_row_path(repository.id, record.id)
      row['rowRemindersUrl'] = Rails.application.routes.url_helpers
                                    .active_reminder_repository_cells_repository_repository_row_url(repository.id, record.id)
      row['relationshipsUrl'] = Rails.application.routes.url_helpers
                                     .relationships_repository_repository_row_url(record.repository_id, record.id)
      row['relationships_enabled'] = repository_row_connections_enabled
      row['hasActiveReminders'] = record.has_active_reminders if reminders_enabled

      unless options[:view_mode]
        row['recordUpdateUrl'] =
          Rails.application.routes.url_helpers.repository_repository_row_path(repository, record)

        # if the editable? property will be checked in a separate request, we can default it to true
        row['recordEditable'] = options[:omit_editable] ? true : record.editable?
      end

      row['0'] = record[:row_assigned] if options[:my_module]

      # Add custom columns
      custom_cells = record.repository_cells.filter { |cell| cell.value_type != 'RepositoryStockValue' }

      custom_cells.each do |cell|
        row[columns_mappings[cell.repository_column_id]] = serialize_repository_cell_value(cell, team, repository, reminders_enabled: reminders_enabled)
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
      elsif stock_management_column_exists
        stock_cell = record.repository_cells.find { |cell| cell.value_type == 'RepositoryStockValue' }
        row['stock'] = serialize_repository_cell_value(record.repository_stock_cell, team, repository) if stock_cell.present?
      end

      row
    end
  end

  def prepare_simple_view_row_columns(repository_rows, repository, my_module, options = {})
    # repository_rows collection is already preloaded in controllers, do not modify scopes or query params
    # otherwise it will result in duplicated SQL queries
    has_stock_management = repository.has_stock_management?
    reminders_enabled = !options[:disable_reminders] && Repository.reminders_enabled?
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

      row['hasActiveReminders'] = record.has_active_reminders if reminders_enabled

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
        '4': escape_input(record.created_by_full_name),
        'recordInfoUrl': Rails.application.routes.url_helpers
                              .repository_repository_row_path(repository_snapshot, record)
      }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column_id]] = serialize_repository_cell_value(cell, team, repository_snapshot)
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
      '6': escape_input(record.created_by_full_name),
      '7': (record.updated_at ? I18n.l(record.updated_at, format: :full) : ''),
      '8': escape_input(record.last_modified_by_full_name),
      '9': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '10': escape_input(record.archived_by_full_name)
    }
  end

  def soft_locked_repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': record.code,
      '3': escape_input(record.name),
      '4': "#{record.parent_connections_count || 0} / #{record.child_connections_count || 0}",
      '5': I18n.l(record.created_at, format: :full),
      '6': escape_input(record.created_by_full_name),
      '7': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '8': escape_input(record.archived_by_full_name)
    }
  end

  def linked_repository_default_columns(record)
    {
      '1': assigned_row(record),
      '2': record.code,
      '3': escape_input(record.name),
      '4': I18n.l(record.created_at, format: :full),
      '5': escape_input(record.created_by_full_name),
      '6': (record.archived_on ? I18n.l(record.archived_on, format: :full) : ''),
      '7': escape_input(record.archived_by_full_name),
      '8': escape_input(record.external_id)
    }
  end

  def serialize_repository_cell_value(cell, team, repository, options = {})
    # case/when is used because it is much faster then .constantize
    serializer_class =
      case cell.repository_column.data_type
      when 'RepositoryTextValue' then RepositoryDatatable::RepositoryTextValueSerializer
      when 'RepositoryNumberValue' then RepositoryDatatable::RepositoryNumberValueSerializer
      when 'RepositoryListValue' then RepositoryDatatable::RepositoryListValueSerializer
      when 'RepositoryChecklistValue' then RepositoryDatatable::RepositoryChecklistValueSerializer
      when 'RepositoryStatusValue' then RepositoryDatatable::RepositoryStatusValueSerializer
      when 'RepositoryTimeValue' then RepositoryDatatable::RepositoryTimeValueSerializer
      when 'RepositoryDateValue' then RepositoryDatatable::RepositoryDateValueSerializer
      when 'RepositoryDateTimeValue' then RepositoryDatatable::RepositoryDateTimeValueSerializer
      when 'RepositoryDateRangeValue' then RepositoryDatatable::RepositoryDateRangeValueSerializer
      when 'RepositoryTimeRangeValue' then RepositoryDatatable::RepositoryTimeRangeValueSerializer
      when 'RepositoryDateTimeRangeValue' then RepositoryDatatable::RepositoryDateTimeRangeValueSerializer
      when 'RepositoryAssetValue' then RepositoryDatatable::RepositoryAssetValueSerializer
      when 'RepositoryStockValue' then RepositoryDatatable::RepositoryStockValueSerializer
      when 'RepositoryStockConsumptionValue' then RepositoryDatatable::RepositoryStockConsumptionValueSerializer
      else
        Extends::REPOSITORY_EXTRA_VALUE_SERIALIZERS[cell.value_type]
      end

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
end
