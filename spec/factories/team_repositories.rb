# frozen_string_literal: true

FactoryBot.define do
  factory :team_repository do
<<<<<<< HEAD
=======
    team
>>>>>>> Finished merging. Test on dev machine (iMac).
    repository
    trait :read do
      permission_level { :shared_read }
    end
    trait :write do
      permission_level { :shared_write }
    end
  end
end
