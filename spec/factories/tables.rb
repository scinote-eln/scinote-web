# frozen_string_literal: true

FactoryBot.define do
  factory :table do
    name { Faker::Name.unique.name }
    contents { { data: [%w(A B C), %w(D E F), %w(G H I)] } }
  end
end
