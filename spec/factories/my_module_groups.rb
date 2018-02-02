FactoryBot.define do
  factory :my_module_group do
    experiment { Experiment.first || create(:experiment_two) }
  end
end
