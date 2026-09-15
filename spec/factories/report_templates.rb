# frozen_string_literal: true

FactoryBot.define do
  factory :report_template do
    name { Faker::Lorem.word }
    subject { create(:protocol) }
  end
end
