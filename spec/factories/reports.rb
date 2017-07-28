FactoryGirl.define do
  factory :report do
    user { User.first || association(:user) }
    project { Project.first || association(:project) }
    name Faker::Name.unique.name
  end
end
