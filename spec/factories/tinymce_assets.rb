# frozen_string_literal: true

FactoryBot.define do
  factory :tiny_mce_asset do
    association :team, factory: :team
<<<<<<< HEAD
    after(:create) do |tiny_mce_asset|
      tiny_mce_asset.image.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')), filename: 'test.jpg')
    end
=======
    image_file_name 'sample_file.jpg'
    image_content_type 'image/jpeg'
    image_file_size 69
>>>>>>> Finished merging. Test on dev machine (iMac).
  end
end
