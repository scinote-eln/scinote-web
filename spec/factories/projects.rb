FactoryBot.define do
  factory :project do
    created_by { User.first || association(:project_user) }
    team { Team.first || association(:project_team) }
    archived false
    name 'My project'
    visibility 'hidden'
  end

  factory :project_user, class: User do
    full_name Faker::Name.name
    initials 'AD'
    email Faker::Internet.email
    password 'asdf1243'
    password_confirmation 'asdf1243'
  end

  factory :project_team, class: Team do
    created_by { User.first || association(:project_user) }
    name 'My team'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing eli.'
    space_taken 1048576
  end
end
