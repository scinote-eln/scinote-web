# frozen_string_literal: true

FactoryBot.define do
  factory :activity_filter do
    name { 'type filter 1' }
    filter { { 'types' => %w(0), 'from_date' => '', 'to_date' => '' } }
  end
end
