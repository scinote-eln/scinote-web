# frozen_string_literal: true

FactoryBot.define do
  factory :user_team do
    user
    team
    trait :admin do
      role { 'admin' }
    end
    trait :guest do
      role { 'guest' }
    end
    trait :normal_user do # default enum by DB
      role { 'normal_user' }
    end
  end
end
