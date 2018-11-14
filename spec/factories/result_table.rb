# frozen_string_literal: true

FactoryBot.define do
  factory :result_table do
    table { create(:table) }
  end
end
