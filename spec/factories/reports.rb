FactoryBot.define do
  factory :report do
    user { User.first || association(:user) }
    project { Project.first || association(:project) }
    team { Team.first || association(:team) }
    name Faker::Name.unique.name
  end
end
