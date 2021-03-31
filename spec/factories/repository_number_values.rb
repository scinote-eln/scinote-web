# frozen_string_literal: true

FactoryBot.define do
  factory :repository_number_value do
    created_by { create :user }
    last_modified_by { created_by }
    data { Faker::Number.decimal(l_digits: 4, r_digits: 4) }
    after(:build) do |repository_number_value|
      repository_number_value.repository_cell ||= build(:repository_cell,
                                                        :number_value,
                                                        repository_number_value: repository_number_value)
      repository_number_value.repository_cell.value = repository_number_value
    end
  end
end
