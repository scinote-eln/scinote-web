# frozen_string_literal: true

FactoryBot.define do
  factory :repository_text_value do
    created_by { create :user }
    last_modified_by { created_by }
    data { Faker::Lorem.paragraph }
    after(:build) do |repository_text_value|
      repository_text_value.repository_cell ||= build(:repository_cell,
                                                      :text_value,
                                                      repository_text_value: repository_text_value)
<<<<<<< HEAD
<<<<<<< HEAD
      repository_text_value.repository_cell.value = repository_text_value
=======
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      repository_text_value.repository_cell.value = repository_text_value
>>>>>>> Pulled latest release
    end
  end
end
