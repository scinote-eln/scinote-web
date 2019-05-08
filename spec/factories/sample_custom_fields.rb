# frozen_string_literal: true

FactoryBot.define do
  factory :sample_custom_field do
    value { Faker::Name.unique.name }
    sample
    custom_field { create :custom_field, user: sample.user, team: sample.team }
  end
end
