class RepositoryTable < ActiveRecord::Base
  belongs_to :user, inverse_of: :repository_tables
  belongs_to :repository, inverse_of: :repository_tables

  validates :user, :repository, presence: true

  scope :load_state, (lambda { |user, repository|
    where(user: user, repository: repository).pluck(:state)
  })

  def self.update_state(custom_column, column_index, user)
    repository_table = RepositoryTable.where(
      user: user,
      repository: custom_column.repository
    )
    repository_state = repository_table.first['state']
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
    repository_table.first.update(state: repository_state)
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
    RepositoryTable.create(user: user,
                           repository: repository,
                           state: repository_state)
  end
end
