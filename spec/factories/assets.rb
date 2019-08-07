# frozen_string_literal: true

FactoryBot.define do
  factory :asset do
    file do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.jpg'), 'image/jpg')
    end
  end
end
