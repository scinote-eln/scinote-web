# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    association :created_by, factory: :user
    name 'My team'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing eli.'
    space_taken 1048576
  end
end
