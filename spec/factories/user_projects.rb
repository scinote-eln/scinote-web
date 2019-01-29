# frozen_string_literal: true

FactoryBot.define do
  factory :user_project do
    user
    project
    assigned_by { user }
    trait :owner do
      role { UserProject.roles[:owner] }
    end
    trait :normal_user do
      role { UserProject.roles[:normal_user] }
    end
    trait :technician do
      role { UserProject.roles[:technician] }
    end
    trait :viewer do
      role { UserProject.roles[:viewer] }
    end
  end
end
