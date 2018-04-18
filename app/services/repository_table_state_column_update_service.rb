class RepositoryTableStateColumnUpdateService
  # We're using Constants::REPOSITORY_TABLE_DEFAULT_STATE as a reference for
  # default table state; this Ruby Hash makes heavy use of Ruby symbols
  # notation; HOWEVER, the state that is saved on the RepositoryTableState
  # record, has EVERYTHING (booleans, symbols, keys, ...) saved as Strings.

  def update_states_with_new_column(new_column)
    RepositoryTableState.where(
      repository: new_column.repository
    ).find_each do |table_state|
      state = table_state.state
      index = state['columns'].count

      # Add new columns, ColReorder, length entries
      state['columns'][index.to_s] =
        HashUtil.deep_stringify_keys_and_values(
          Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE
        )
      state['ColReorder'] << index.to_s
      state['length'] = (index + 1).to_s
      state['time'] = Time.new.to_i.to_s
      table_state.save
    end
  end

  def update_states_with_removed_column(repository, old_column_index)
    RepositoryTableState.where(
      repository: repository
    ).find_each do |table_state|
      state = table_state.state

      # old_column_index is a String!

      # Remove column from ColReorder, columns, length entries
      state['columns'].delete(old_column_index)
      state['columns'].keys.each do |index|
        if index.to_i > old_column_index.to_i
          state['columns'][(index.to_i - 1).to_s] =
            state['columns'].delete(index.to_s)
        end
      end

      state['ColReorder'].delete(old_column_index)
      state['ColReorder'].map! do |index|
        if index.to_i > old_column_index.to_i
          (index.to_i - 1).to_s
        else
          index
        end
      end
      state['length'] = (state['length'].to_i - 1).to_s
      state['time'] = Time.new.to_i.to_s
      table_state.save
    end
  end
end