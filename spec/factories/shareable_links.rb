FactoryBot.define do
  factory :shareable_link do
    description { Faker::Lorem.sentence }
    association :shareable, factory: :my_module
    team { shareable.team }
    association :created_by, factory: :user
    association :last_modified_by, factory: :user

    after(:build) do |shareable_link|
      shareable_link.uuid = shareable_link.shareable.signed_id
    end
  end
end
