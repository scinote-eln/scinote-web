# frozen_string_literal: true

FactoryBot.define do
  factory :repository_row do
    sequence(:name) { |n| "My row-#{n}" }
    created_by { create :user }
    repository
    last_modified_by { created_by }

    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end

    trait :restored do
      archived { false }
      restored_on { Time.zone.now }
      restored_by { created_by }
    end

    trait :with_children do
      transient do
        nbr_of_children { 2 }
      end

      after(:create) do |repository_row, evaluator|
        evaluator.nbr_of_children.times do
          child_row_repository = create(:repository)
          child_row = create(:repository_row, repository: child_row_repository)
          repository_row.child_connections.create!(child: child_row,
                                                   created_by: repository_row.created_by,
                                                   last_modified_by: repository_row.created_by)
        end
      end
    end

    trait :with_parents do
      transient do
        nbr_of_parents { 2 }
      end

      after(:create) do |repository_row, evaluator|
        evaluator.nbr_of_parents.times do
          parent_row_repository = create(:repository)
          parent_row = create(:repository_row, repository: parent_row_repository)
          repository_row.parent_connections.create!(parent: parent_row,
                                                    created_by: repository_row.created_by,
                                                    last_modified_by: repository_row.created_by)
        end
      end
    end
  end
end
