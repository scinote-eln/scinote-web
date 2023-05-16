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
    end

    trait :in_repository_draft do
      my_module { nil }
      protocol_type { :in_repository_draft }
    end

    trait :in_repository_published_original do
      my_module { nil }
      protocol_type { :in_repository_published_original }
      version_number { 1 }
      published_on { Time.now }
    end

    trait :in_repository_published_version do
      my_module { nil }
      protocol_type { :in_repository_published_version }
      published_on { Time.now }
    end
  end
end
