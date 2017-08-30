FactoryGirl.define do
  factory :my_module_group do
    name Faker::Name.unique.name
    experiment { Experiment.first || create(:experiment_two) }
  end
end
