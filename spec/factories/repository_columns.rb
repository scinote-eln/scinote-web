FactoryBot.define do
  factory :repository_column do
    name 'My Column'
    created_by { User.first || create(:user) }
    repository { Repository.first || create(:repository) }
    data_type :RepositoryTextValue
  end
end
