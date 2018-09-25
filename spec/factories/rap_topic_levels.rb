FactoryBot.define do
  factory :rap_topic_level do#, class RapTopicLevel do
    name "TestRapTopicLevel"
    # rap_program_level RapProgramLevel.first
    rap_program_level { RapProgramLevel.first || association(:rap_program_level) }
  end
end
