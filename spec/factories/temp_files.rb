# frozen_string_literal: true

FactoryBot.define do
  factory :temp_file do
<<<<<<< HEAD
<<<<<<< HEAD
    session_id { Faker::Lorem.characters(number: 20) }
=======
    session_id { Faker::Lorem.characters(20) }
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    session_id { Faker::Lorem.characters(number: 20) }
>>>>>>> Initial commit of 1.17.2 merge
  end
end
