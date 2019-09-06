# frozen_string_literal: true

FactoryBot.define do
  factory :wopi_discovery do
<<<<<<< HEAD
    proof_key_mod { Faker::Lorem.characters(number: 20) }
    proof_key_exp { Faker::Lorem.characters(number: 20) }
    proof_key_old_mod { Faker::Lorem.characters(number: 20) }
    proof_key_old_exp { Faker::Lorem.characters(number: 20) }
=======
    proof_key_mod { Faker::Lorem.characters(20) }
    proof_key_exp { Faker::Lorem.characters(20) }
    proof_key_old_mod { Faker::Lorem.characters(20) }
    proof_key_old_exp { Faker::Lorem.characters(20) }
>>>>>>> Finished merging. Test on dev machine (iMac).
    expires { 60 }
  end
end
