# frozen_string_literal: true

FactoryBot.define do
  factory :team_repository do
<<<<<<< HEAD
<<<<<<< HEAD
=======
    team
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Initial commit of 1.17.2 merge
    repository
    trait :read do
      permission_level { :shared_read }
    end
    trait :write do
      permission_level { :shared_write }
    end
  end
end
