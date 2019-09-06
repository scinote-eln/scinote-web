# frozen_string_literal: true

FactoryBot.define do
  factory :token do
<<<<<<< HEAD
    token { Faker::Lorem.characters(number: 100) }
=======
    token { Faker::Lorem.characters(100) }
>>>>>>> Finished merging. Test on dev machine (iMac).
    ttl { 60 }
    user
  end
end
