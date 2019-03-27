# frozen_string_literal: true

FactoryBot.define do
  factory :checklist_item do
    text { Faker::Lorem.sentence(10) }
    checklist
    checked { false }
  end
end
