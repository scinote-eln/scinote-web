FactoryBot.define do
  factory :editing_flag do
    association :user
    association :subject, factory: :step
    timeout_at { EditingFlag::DEFAULT_DURATION.from_now }
  end
end
