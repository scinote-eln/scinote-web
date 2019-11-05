FactoryBot.define do
  factory :rap_task_level do#, class: RapTaskLevel do
    name { "TestRapTaskLevel" }
    rap_project_level { RapProjectLevel.first || association(:rap_project_level) }
  end
end
