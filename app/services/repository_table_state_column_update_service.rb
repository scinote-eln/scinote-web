# frozen_string_literal: true

class RepositoryTableStateColumnUpdateService
  # We're using Constants::REPOSITORY_TABLE_DEFAULT_STATE as a reference for
  # default table state; this Ruby Hash makes heavy use of Ruby symbols
  # notation; HOWEVER, the state that is saved on the RepositoryTableState
  # record, has EVERYTHING (booleans, symbols, keys, ...) saved as Strings.

  def update_states_with_new_column(repository)
    raise ArgumentError, 'repository is empty' if repository.blank?

    columns_num = repository.default_columns_count + repository.repository_columns.count
    RepositoryTableState.where(
      repository: repository
    ).find_each do |table_state|
      state = table_state.state
      next if state['columns'].length == columns_num

      index = state['columns'].length

      # Add new columns, ColReorder, length entries
      state['columns'][index] = Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE
      state['ColReorder'] << index
      state['time'] = (Time.now.to_f * 1_000).to_i
      table_state.save
    end
  end

  def update_states_with_removed_column(repository, old_column_index)
    raise ArgumentError, 'repository is empty' if repository.blank?
    raise ArgumentError, 'old_column_index is empty' if old_column_index.blank?

    RepositoryTableState.where(repository: repository).find_each do |table_state|
      state = table_state.state
      user = table_state.user

      begin
        # Remove column from ColReorder, columns, length entries
        state['columns'].delete_at(old_column_index)
        state['ColReorder'].delete(old_column_index)
        state['ColReorder'].map! do |index|
          if index > old_column_index
            index - 1
          else
            index
          end
        end

        if state.dig('order', 0, 0).to_i == old_column_index
          # Fallback to default order if user had table ordered by
          # the deleted column
          state['order'] = repository.default_table_state['order']
        elsif state.dig('order', 0, 0).to_i > old_column_index
          state['order'][0][0] -= 1
        end

        state['time'] = (Time.now.to_f * 1_000).to_i
        table_state.save
      rescue StandardError => e
        Rails.logger.error e.message
        RepositoryTableStateService.new(user, repository).create_default_state
      end
    end
  end
end
