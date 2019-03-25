# frozen_string_literal: true

FactoryBot.define do
  factory :repository_cell do
    repository_row
    repository_column
    value 'RepositoryTextValue'
  end
end
