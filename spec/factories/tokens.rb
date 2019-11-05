# frozen_string_literal: true

FactoryBot.define do
  factory :token do
<<<<<<< HEAD
<<<<<<< HEAD
    token { Faker::Lorem.characters(number: 100) }
=======
    token { Faker::Lorem.characters(100) }
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    token { Faker::Lorem.characters(number: 100) }
>>>>>>> Initial commit of 1.17.2 merge
    ttl { 60 }
    user
  end
end
