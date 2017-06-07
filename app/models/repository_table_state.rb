class RepositoryTableState < ActiveRecord::Base
  belongs_to :user, inverse_of: :repository_table_states
  belongs_to :repository, inverse_of: :repository_table_states

  validates :user, :repository, presence: true

  def self.load_state(user, repository)
    table_state = where(user: user, repository: repository).pluck(:state)
    if table_state.blank?
      RepositoryTableState.create_state(user, repository)
      table_state = where(user: user, repository: repository).pluck(:state)
    end
    table_state
  end

  def self.update_state(custom_column, column_index, user)
    table_state = RepositoryTableState.where(
      user: user,
      repository: custom_column.repository
    )
    return if table_state.empty?
    repository_state = table_state.first['state']
    if column_index
      # delete column
      repository_state['columns'].delete(column_index)
      repository_state['columns'].keys.each do |index|
        if index.to_i > column_index.to_i
          repository_state['columns'][(index.to_i - 1).to_s] =
            repository_state['columns'].delete(index)
        else
          index
        end
      end
      repository_state['ColReorder'].delete(column_index)
      repository_state['ColReorder'].map! do |index|
        if index.to_i > column_index.to_i
          (index.to_i - 1).to_s
        else
          index
        end
      end
    else
      # add column
      index = repository_state['columns'].count
      repository_state['columns'][index] = RepositoryDatatable::
        REPOSITORY_TABLE_DEFAULT_STATE['columns'].first
      repository_state['ColReorder'].insert(2, index)
    end
    table_state.first.update(state: repository_state)
  end

  def self.create_state(user, repository)
    default_columns_num = RepositoryDatatable::
                          REPOSITORY_TABLE_DEFAULT_STATE['columns'].count
    repository_state =
      RepositoryDatatable::REPOSITORY_TABLE_DEFAULT_STATE.deep_dup
    repository.repository_columns.each_with_index do |_, index|
      repository_state['columns'] << RepositoryDatatable::
                               REPOSITORY_TABLE_DEFAULT_STATE['columns'].first
      repository_state['ColReorder'] << (default_columns_num + index)
    end
    RepositoryTableState.create(user: user,
                                repository: repository,
                                state: repository_state)
  end
end
