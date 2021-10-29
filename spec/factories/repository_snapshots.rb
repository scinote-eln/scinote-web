# frozen_string_literal: true

FactoryBot.define do
  factory :repository_snapshot do
    name { original_repository.name }
    status { :ready }
    created_by { original_repository.created_by }
    team { original_repository.team }
    original_repository { repository }
    my_module
  end
end
