# frozen_string_literal: true

FactoryBot.define do
  factory :protocol do
    name { Faker::Name.unique.name }
    team
    my_module
    trait :in_public_repository do
      my_module { nil }
      protocol_type { :in_repository_public }
      added_by { create :user }
      published_on { Time.now }
    end
    trait :linked_to_repository do
      protocol_type { :linked }
      parent { create :protocol }
      added_by { create :user }
      parent_updated_at { Time.now }
    end
  end
end
