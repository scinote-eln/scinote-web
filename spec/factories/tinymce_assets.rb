# frozen_string_literal: true

FactoryBot.define do
  factory :tiny_mce_asset do
    association :team, factory: :team
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    after(:create) do |tiny_mce_asset|
      tiny_mce_asset.image.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')), filename: 'test.jpg')
    end
=======
    image_file_name 'sample_file.jpg'
    image_content_type 'image/jpeg'
    image_file_size 69
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    image do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.jpg'), 'image/jpg')
=======
    after(:create) do |tiny_mce_asset|
      tiny_mce_asset.image.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')), filename: 'test.jpg')
>>>>>>> Pulled latest release
    end
>>>>>>> Initial commit of 1.17.2 merge
  end
end
