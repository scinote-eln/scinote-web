FactoryBot.define do
  factory :project do
    created_by { User.first || association(:project_user) }
    team { Team.first || association(:project_team) }
    #@@@20180925JS - Add RapTaskLevel to the factory for projects
    # rap_task_level { RapTaskLevel.first } # db.seed should be a prereq for this, so do we need the association?
    rap_task_level { RapTaskLevel.first || association(:rap_task_level) }
    archived false
    name 'My project'
    visibility 'hidden'
  end

  factory :project_user, class: User do
    full_name Faker::Name.name
    initials 'AD'
    email Faker::Internet.email
    password 'asdf1243'
    password_confirmation 'asdf1243'
  end

  factory :project_team, class: Team do
    created_by { User.first || association(:project_user) }
    name 'My team'
    description 'Lorem ipsum dolor sit amet, consectetuer adipiscing eli.'
    space_taken 1048576
  end

  # factory :project_rap_task_level, class: RapTaskLevel do
  #   rap_project_level_id { RapProjectLevel.first || association(:project_rap_project_level) }
  #   name 'TestRapTaskLevel'
  # end

  # factory :project_rap_project_level, class RapProjectLevel do
  #   rap_topic_level_id { RapTopicLevel.first || association(:project_rap_topic_level) }
  #   name 'TestRapProjectLevel'
  # end

  # factory :project_rap_topic_level, class RapTopicLevel do
  #   rap_program_level_id { RapProgramLevel.first || association(:project_rap_program_level) }
  #   name 'TestRapTopicLevel'
  # end

  # factory :project_rap_program_level, class RapProgramLevel do
  #   name 'TestRapProgramLevel'
  # end
  
end
