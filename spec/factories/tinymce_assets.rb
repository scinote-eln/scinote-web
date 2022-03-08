# frozen_string_literal: true

FactoryBot.define do
  factory :tiny_mce_asset do
    association :team, factory: :team
    after(:create) do |tiny_mce_asset|
      tiny_mce_asset.image.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')), filename: 'test.jpg')
    end
  end
end
