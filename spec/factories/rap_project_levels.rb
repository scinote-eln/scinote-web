FactoryBot.define do
  factory :rap_project_level do#, class RapProjectLevel do
    name "TestRapProjectLevel"
    # rap_topic_level RapTopicLevel.first
    rap_topic_level { RapTopicLevel.first || association(:rap_topic_level) }
  end
end
