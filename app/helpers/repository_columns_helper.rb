module RepositoryColumnsHelper
  def form_url(repository, column)
    return repository_repository_columns_path(repository) if column.new_record?
    repository_repository_column_path(repository, column)
  end

  def disabled?(column, type)
    return false if column.new_record?
    column.data_type != type
  end

  def checked?(column, type)
    return true if column.new_record? && type == 'RepositoryTextValue'
    return true if column.data_type == type
  end
end
