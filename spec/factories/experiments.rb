FactoryBot.define do
  factory :experiment do
    name { Faker::Name.unique.name }
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.'
  end

  factory :experiment_one, class: Experiment do
    name 'My Experiment One'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.'
    association :project, factory: :project
    association :created_by, factory: :user, email: Faker::Internet.email
    association :last_modified_by,
                factory: :user,
                email: Faker::Internet.email
  end

  factory :experiment_two, class: Experiment do
    name Faker::Name.name
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.'
    association :project, factory: :project
    association :created_by, factory: :user, email: Faker::Internet.email
    association :last_modified_by,
                factory: :user,
                email: Faker::Internet.email
  end
end
