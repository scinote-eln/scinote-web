FactoryBot.define do
  factory :repository_cell do
    repository_row { RepositoryRow.first || create(:repository_row) }
    repository_column do
      RepositoryColumn.first || create(:repository_column)
    end
    value 'RepositoryTextValue'
  end
end
