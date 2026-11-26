# frozen_string_literal: true

class MigrateInventoryTableSettings < ActiveRecord::Migration[7.2]
  # Legacy DataTables columns in original order, mapped to new table colIds (nil = no longer exists).
  # Legacy state indexes ('columns', 'order', 'ColReorder' values) refer to these positions, custom columns follow.
  LEGACY_BASIC_COLUMNS = [
    nil, # checkbox
    'assigned_tasks_count',
    'code',
    'name',
    'connections_count', # relationships, always present even when the feature is disabled
    'created_at',
    'created_by',
    'updated_at',
    'last_modified_by',
    'archived_on',
    'archived_by'
  ].freeze
  ARCHIVED_COLUMNS = %w(archived_on archived_by).freeze
  VIEW_MODES = %w(active archived).freeze

  # Not critical, it must never block a release: no wrapping transaction, so a failed state can't abort
  # the migration, and existing settings are skipped, so it's safe to rerun
  disable_ddl_transaction!

  def up
    stats = Hash.new(0)

    # ids only, instantiating repositories could fail for STI types from addons that are not loaded
    Repository.pluck(:id).each do |repository_id|
      legacy_columns = LEGACY_BASIC_COLUMNS.dup
      RepositoryColumn.where(repository_id: repository_id).order(:id).pluck(:id, :data_type).each do |id, data_type|
        legacy_columns << (data_type == 'RepositoryStockValue' ? 'stock' : "col_#{id}")
      end

      RepositoryTableState.where(repository_id: repository_id).find_each do |table_state|
        old_state = table_state.state

        # States saved before relationship (2023) and updated on/by (2024) columns were added
        # were already ignored by the legacy table, so users get the new default state
        unless old_state.is_a?(Hash) && old_state['columns'].is_a?(Array) && old_state['columns'].length == legacy_columns.length
          stats[:skipped] += 1
          next
        end

        VIEW_MODES.each do |view_mode|
          key = "repository_table_#{repository_id}_#{view_mode}_table_state"
          next if UserSetting.exists?(user_id: table_state.user_id, key: key)

          UserSetting.create!(user_id: table_state.user_id, key: key, value: new_state(old_state, legacy_columns, view_mode))
        end
        stats[:migrated] += 1
      rescue StandardError => e
        stats[:failed] += 1
        Rails.logger.error("Failed to migrate repository table state #{table_state.id}: #{e.message}")
      end
    rescue StandardError => e
      stats[:failed_repositories] += 1
      Rails.logger.error("Failed to migrate table states of repository #{repository_id}: #{e.message}")
    end

    say "Inventory table states: #{stats.inspect}"
  end

  private

  def new_state(old_state, legacy_columns, view_mode)
    order_column = legacy_columns[old_state.dig('order', 0, 0).to_i]

    {
      columnsState: columns_state(old_state, legacy_columns, view_mode),
      order: order_column && { column: order_column, dir: old_state.dig('order', 0, 1) == 'desc' ? 'desc' : 'asc' },
      currentViewRender: 'table',
      perPage: [10, 20, 50, 100].include?(old_state['length'].to_i) ? old_state['length'].to_i : 20
    }
  end

  def columns_state(old_state, legacy_columns, view_mode)
    # ColReorder[position] = original index, ColSizes are in display order
    display_order = Array(old_state['ColReorder']).map(&:to_i)
    display_order = (0...legacy_columns.length).to_a if display_order.sort != (0...legacy_columns.length).to_a

    # legacy table always showed archived columns in archived view
    always_visible = %w(name assigned_tasks_count)
    always_visible += ARCHIVED_COLUMNS if view_mode == 'archived'

    columns = display_order.each_with_index.filter_map do |index, position|
      col_id = legacy_columns[index]
      next if col_id.nil?
      next if view_mode == 'active' && ARCHIVED_COLUMNS.include?(col_id)

      column_state(
        col_id,
        width: old_state.dig('ColSizes', position).to_i.nonzero?,
        hide: always_visible.exclude?(col_id) && old_state.dig('columns', index, 'visible') == false
      )
    end

    # new column which does not exist in old state
    columns.unshift(column_state('active_reminders_count'))
  end

  def column_state(col_id, width: nil, hide: false)
    {
      colId: col_id,
      width: width,
      hide: hide,
      pinned: %w(active_reminders_count name).include?(col_id) ? 'left' : nil,
      sort: nil,
      sortIndex: nil,
      aggFunc: nil,
      rowGroup: false,
      rowGroupIndex: nil,
      pivot: false,
      pivotIndex: nil,
      flex: nil
    }
  end
end
