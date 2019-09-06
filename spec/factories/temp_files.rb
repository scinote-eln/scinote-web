# frozen_string_literal: true

FactoryBot.define do
  factory :temp_file do
<<<<<<< HEAD
    session_id { Faker::Lorem.characters(number: 20) }
=======
    session_id { Faker::Lorem.characters(20) }
>>>>>>> Finished merging. Test on dev machine (iMac).
  end
end
