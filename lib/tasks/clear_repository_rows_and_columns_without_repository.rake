namespace :clear_repository_rows_and_columns_without_repository do
  desc 'Removes all repository rows/columns and ' \
       'referenced entities with dependent: destroy'
  task run: :environment do
    repository_ids = Repository.select(:id)
    RepositoryColumn.skip_callback(:destroy, :around, :update_repository_table_states_with_removed_column)
    RepositoryRow.where.not(repository_id: repository_ids).destroy_all
    RepositoryColumn.where.not(repository_id: repository_ids).destroy_all
    RepositoryColumn.set_callback(:destroy, :around, :update_repository_table_states_with_removed_column)
  end
end
