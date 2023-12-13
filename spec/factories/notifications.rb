# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    recipient_type { 'User' }
    recipient_id { FactoryBot.create(:user).id }
    read_at { Time.now }
  end
end
