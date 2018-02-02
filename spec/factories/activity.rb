FactoryBot.define do
  factory :activity do
    type_of :create_project
    message Faker::Lorem.sentence(10)
    project { Project.first || create(:project) }
  end
end
