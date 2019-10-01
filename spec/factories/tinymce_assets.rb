# frozen_string_literal: true

FactoryBot.define do
  factory :tiny_mce_asset do
    association :team, factory: :team
    image do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.jpg'), 'image/jpg')
    end
  end
end
