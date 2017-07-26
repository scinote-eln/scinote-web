FactoryGirl.define do
  factory :user do
    full_name 'admin'
    initials 'AD'
    email 'admin@scinote.net'
    password 'asdf1243'
    password_confirmation 'asdf1243'
  end
end
