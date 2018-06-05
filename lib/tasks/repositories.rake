namespace :repositories do
  desc 'Removes all repository rows/columns and ' \
       'referenced entities with dependent: destroy'
  task remove_rows_and_columns_without_repository: :environment do
    repository_ids = Repository.select(:id)
    RepositoryColumn.skip_callback(
      :destroy, :around, :update_repository_table_states_with_removed_column
    )
    RepositoryRow.where.not(repository_id: repository_ids).destroy_all
    RepositoryColumn.where.not(repository_id: repository_ids).destroy_all
    RepositoryColumn.set_callback(
      :destroy, :around, :update_repository_table_states_with_removed_column
    )
  end

  desc 'Set\'s the Name column visibility value to true. Needed if ' \
       'the user has the Name column hidden when [SCI-2435] is merged. ' \
       'Check: https://github.com/biosistemika/scinote-web/commits/master'
  task set_name_column_visibility: :environment do
    RepositoryTableState.find_each do |repository_table_state|
      next unless repository_table_state.state['columns']['3']
      repository_table_state.state['columns']['3']['visible'] = 'true'
      repository_table_state.save
    end
  end
end
