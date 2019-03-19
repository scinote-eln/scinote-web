FactoryBot.define do
  factory :tiny_mce_asset do
    association :team, factory: :team
    image_file_name 'sample_file.jpg'
    image_content_type 'image/jpeg'
    image_file_size 69
  end
end
