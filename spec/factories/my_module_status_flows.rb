# frozen_string_literal: true

FactoryBot.define do
  factory :my_module_status_flow do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    trait :in_team do
      team { create :team }
      visibility { :in_team }
    end
  end
end
