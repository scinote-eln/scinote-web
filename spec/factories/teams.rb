# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    association :created_by, factory: :user
    sequence(:name) { |n| "My team-#{n}" }
    description { Faker::Lorem.sentence }
    space_taken { 1048576 }
    without_templates { true }
    trait :change_user_team do
      after(:create) do |team|
        team.created_by.update(current_team_id: team.id)
      end
    end
    trait :with_members do
      users { create_list :user, 3 }
    end
    trait :record_deletion_enabled do
      after(:create) do |team|
        team.update!(
          settings:
            team.settings.merge(
              {
                'repository_deletion_enabled' => true,
                'result_deletion_enabled' => true
              }
            )
        )
      end
    end
  end
end
