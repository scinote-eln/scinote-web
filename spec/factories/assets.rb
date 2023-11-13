# frozen_string_literal: true

FactoryBot.define do
  factory :asset do
    team
    after(:create) do |asset|
      asset.file.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')), filename: 'test.jpg')
    end
  end
end
