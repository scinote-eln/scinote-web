namespace :clear_repository_rows_and_columns_without_repository do
  desc 'Removes all repository rows/columns and ' \
       'referenced entities with dependent: destroy'
  task run: :environment do
    repository_ids = Repository.select(:id)
    RepositoryRow.where.not(repository_id: repository_ids).delete_all
    RepositoryColumn.where.not(repository_id: repository_ids).delete_all
  end
end
