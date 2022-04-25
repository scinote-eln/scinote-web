# frozen_string_literal: true

module RepositoryDatatableHelper
  include InputSanitizeHelper

  def prepare_row_columns(repository_rows, repository, columns_mappings, team, options = {})
    reminder_row_ids = repository_reminder_row_ids(repository_rows, repository)

    repository_rows.map do |record|
      default_cells = public_send("#{repository.class.name.underscore}_default_columns", record)
      row = {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        'recordInfoUrl': Rails.application.routes.url_helpers.repository_repository_row_path(repository, record),
        'hasActiveReminders': reminder_row_ids.include?(record.id),
        'rowRemindersUrl':
          Rails.application.routes.url_helpers
               .active_reminder_repository_cells_repository_repository_row_url(
                 repository,
                 record
               )
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
      custom_cells = record.repository_cells.where.not(value_type: 'RepositoryStockValue')

      custom_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] =
          display_cell_value(cell, team, repository)
      end

      stock_present = record.repository_stock_cell.present?
      stock_managable = !options[:disable_stock_management] && can_manage_repository_stock?(record.repository)

      # always add stock cell, even if empty
      row['stock'] = stock_present ? display_cell_value(record.repository_stock_cell, team, repository) : {}
      row['stock'][:stock_managable] = stock_managable
      row['stock']['displayWarnings'] = display_stock_warnings?(repository)
      row['stock'][:stock_status] = record.repository_stock_cell&.value&.status

      row['stock']['value_type'] = 'RepositoryStockValue'

      if options[:include_stock_consumption] && record.repository.has_stock_management? && options[:my_module]
        consumption_managable = stock_consumption_managable?(record, repository, options[:my_module])
        consumed_stock_formatted =
          number_with_precision(
            record.consumed_stock,
            precision: (record.repository.repository_stock_column.metadata['decimals'].to_i || 0),
            strip_insignificant_zeros: true
          )
        row['consumedStock'] = {
          stock_present: stock_present,
          consumptionPermitted: stock_consumption_permitted?(repository, options[:my_module]),
          consumptionManagable: consumption_managable,
          updateStockConsumptionUrl: Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
            options[:my_module],
            record.repository,
            row_id: record.id
          ),
          value: {
            consumed_stock: record.consumed_stock,
            consumed_stock_formatted:
              "#{consumed_stock_formatted || 0} #{record.repository_stock_value&.repository_stock_unit_item&.data}"
          }
        }
      end

      row
    end
  end

  def prepare_simple_view_row_columns(repository_rows, repository, my_module, options = {})
    reminder_row_ids = repository_reminder_row_ids(repository_rows, repository)

    repository_rows.map do |record|
      row = {
        DT_RowId: record.id,
        DT_RowAttr: { 'data-state': row_style(record) },
        '0': escape_input(record.name),
        recordInfoUrl: Rails.application.routes.url_helpers.repository_repository_row_path(record.repository, record),
        'hasActiveReminders': reminder_row_ids.include?(record.id),
        'rowRemindersUrl':
          Rails.application.routes.url_helpers
               .active_reminder_repository_cells_repository_repository_row_url(
                 record.repository,
                 record
               )
      }

      if options[:include_stock_consumption] && record.repository.has_stock_management?
        stock_present = record.repository_stock_cell.present?
        # Always disabled in a simple view
        stock_managable = false

        consumption_managable = stock_consumption_managable?(record, repository, my_module)

        row['stock'] = stock_present ? display_cell_value(record.repository_stock_cell, record.repository.team, repository) : {}
        row['stock']['displayWarnings'] = display_stock_warnings?(repository)
        row['stock'][:stock_status] = record.repository_stock_cell&.value&.status

        row['stock'][:stock_managable] = stock_managable
        if record.repository.is_a?(RepositorySnapshot)
          row['consumedStock'] =
            if record.repository_stock_consumption_value.present?
              display_cell_value(record.repository_stock_consumption_cell, record.repository.team, repository)
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
        row['consumedStock']['consumptionPermitted'] = stock_consumption_permitted?(repository, my_module)
        row['consumedStock']['consumptionManagable'] = consumption_managable
      end

      row
    end
  end

  def prepare_snapshot_row_columns(repository_rows, columns_mappings, team, repository_snapshot, options = {})
    repository_rows.map do |record|
      row = {
        'DT_RowId': record.id,
        'DT_RowAttr': { 'data-state': row_style(record) },
        '1': record.code,
        '2': escape_input(record.name),
        '3': I18n.l(record.created_at, format: :full),
        '4': escape_input(record.created_by.full_name),
        'recordInfoUrl': Rails.application.routes.url_helpers.repository_repository_row_path(repository_snapshot, record)
      }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[columns_mappings[cell.repository_column.id]] = display_cell_value(cell, team, repository_snapshot)
      end

      if options[:include_stock_consumption] && repository_snapshot.has_stock_management?
        stock_present = record.repository_stock_cell.present?
        row['stock'] = if stock_present
                         display_cell_value(record.repository_stock_cell, team, repository_snapshot)
                       else
                         { value_type: 'RepositoryStockValue' }
                       end

        row['consumedStock'] =
          if stock_present
            display_cell_value(record.repository_stock_consumption_cell, team, repository_snapshot)
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
      '5': escape_input(record.created_by.full_name),
      '6': I18n.l(record.created_at, format: :full)
    }
  end

  def display_cell_value(cell, team, repository)
    serializer_class = "RepositoryDatatable::#{cell.repository_column.data_type}Serializer".constantize
    serializer_class.new(
      cell.value,
      scope: {
        team: team,
        user: current_user,
        column: cell.repository_column,
        repository: repository
      }
    ).serializable_hash
  end

  def row_style(row)
    return I18n.t('general.archived') if row.archived

    ''
  end

  def repository_reminder_row_ids(repository_rows, repository)
    # don't load reminders if the stock management feature is disabled
    return [] unless RepositoryBase.stock_management_enabled?

    # don't load reminders for archived repositories
    return [] if repository_rows.blank? || repository.archived?

    repository_rows.active.with_active_reminders(current_user).to_a.pluck(:id).uniq
  end

  def stock_consumption_permitted?(repository, my_module)
    return false unless repository.is_a?(Repository)

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
