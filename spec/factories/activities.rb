# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    type_of { :create_project }
    message { Faker::Lorem.sentence(word_count: 10) }
    subject { create :project }
    owner { create :user }
    team
    trait :old do
      project
      experiment
      subject { nil }
    end
  end
end
