# frozen_string_literal: true

FactoryBot.define do
  factory :repository_table_state do
    user
    repository
    state { {} }
  end
end
