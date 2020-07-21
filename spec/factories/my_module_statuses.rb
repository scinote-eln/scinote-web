# frozen_string_literal: true

FactoryBot.define do
  factory :my_module_status do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    color { Faker::Color.hex_color }
    my_module_status_flow
  end
end
