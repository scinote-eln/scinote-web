FactoryBot.define do
  factory :user do
    full_name 'admin'
    initials 'AD'
    email Faker::Internet.unique.email
    password 'asdf1243'
    password_confirmation 'asdf1243'
    current_sign_in_at DateTime.now
  end
end
