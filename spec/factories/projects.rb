FactoryGirl.define do
  factory :project do
    association :created_by, factory: :project_user
    association :team, factory: :team
    archived false
    name 'My project'
    visibility 'hidden'
  end

  factory :project_user, class: 'User' do
    full_name Faker::Name.name
    initials 'AD'
    email Faker::Internet.email
    password 'asdf1243'
    password_confirmation 'asdf1243'
  end

  factory :project_team do
    association :created_by, factory: :project_user
    name 'My team'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing eli.'
    space_taken 1048576
  end
end
