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
  end
end
