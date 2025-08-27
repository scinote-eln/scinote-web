# frozen_string_literal: true

FactoryBot.define do
  factory :tagging do
    tag
    association :taggable, factory: :my_module
  end
end
