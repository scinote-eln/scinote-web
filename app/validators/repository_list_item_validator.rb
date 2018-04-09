class RepositoryListItemValidator < ActiveModel::Validator
  def validate(record)
    return unless record.repository_column
    items_length = record.repository_column.repository_list_items.size
    if items_length >= Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
      record.errors[:items_limit] << 'Maximum number of list items reached!'
    end
  end
end
