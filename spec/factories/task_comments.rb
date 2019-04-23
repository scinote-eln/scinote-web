# frozen_string_literal: true

FactoryBot.define do
  factory :task_comment do
    user
    my_module
    message { Faker::Lorem.sentence }
  end
end
