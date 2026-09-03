# frozen_string_literal: true

class MigrateInventoryTableSettings < ActiveRecord::Migration[7.2]
  def up
    basic_column_names = %w(
      checkbox
      assigned
      id
      name
      created_at
      created_by
      updated_at
      updated_by
      archived_at
      archived_by
      external_id
    )

    default_column_state = lambda do |name|
      {
        colId: name,
        width: nil,
        hide: false,
        pinned: nil,
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

    basic_columns = []
    basic_column_names.each_with_index do |name, _index|
      basic_columns << default_column_state.call(name)
    end

    Repository.find_each do |repository|
      repository_default_state = basic_columns.dup
      repository.repository_columns.order(:id).find_each do |column|
        repository_default_state << default_column_state.call("col_#{column.id}")
      end

      repository.repository_table_states.includes(:user).find_each do |table_state|
        old_state = table_state.state
        columns = repository_default_state.dup

        columns.each_with_index do |column, index|
          column['width'] = old_state.dig('ColSizes', index)
          column['hide'] = if column['colId'] == 'name' # name column is always visible
                             false
                           else
                             !old_state.dig('columns', index, 'visible')
                           end
        end

        order = {
          column: columns[old_state.dig('order', 0, 0)]['colId'],
          dir: old_state.dig('order', 0, 1)
        }

        reorder_columns = []

        # apply order
        old_state['ColReorder'].each do |old_index|
          reorder_columns << columns[old_index]
        end

        # new column which not exist in old state
        reorder_columns.unshift(default_column_state.call('active_reminders_count'))

        new_state = {
          columnsState: reorder_columns,
          order: order,
          currentViewRender: 'table',
          perPage: old_state['length']
        }

        # Same state is used for both active and archived
        UserSetting.create!(
          user: table_state.user,
          key: "repository_table_#{repository.id}_active_table_state",
          value: new_state
        )
        UserSetting.create!(
          user: table_state.user,
          key: "repository_table_#{repository.id}_archived_table_state",
          value: new_state
        )
      end
    end
  end
end
