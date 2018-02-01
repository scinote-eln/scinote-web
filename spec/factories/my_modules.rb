FactoryBot.define do
  factory :my_module do
    name 'My first module'
    x 0
    y 0
    workflow_order 0
    experiment { Experiment.first || create(:experiment_one) }
    my_module_group { MyModuleGroup.first || create(:my_module_group) }
  end
end
