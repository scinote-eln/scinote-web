class RemoveRepositoryRowsAndColumnsWithoutRepository < ActiveRecord::Migration[5.1]
  def up
    if column_exists?(:repositories, :discarded_at)
      repository_ids = Repository.select(:id)
      RepositoryRow.where.not(repository_id: repository_ids).delete_all
      RepositoryColumn.where.not(repository_id: repository_ids).delete_all
    end
  end
end
