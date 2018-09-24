module RapGenerator
  def validate_rap_program_level(name, created_at, updated_at)
    new_rap_program = RapProgramLevel.new(
      name: name, created_at: created_at, updated_at: updated_at
    )
    new_rap_program.validate
    new_rap_program.errors
  end

  def validate_rap_topic_level(name, program_id, created_at, updated_at)
    new_rap_topic = RapTopicLevel.new(
      name: name, rap_program_level_id: program_id, created_at: created_at, updated_at: updated_at
    )
    new_rap_topic.validate
    new_rap_topic.errors
  end
  
  def validate_rap_project_level(name, topic_id, created_at, updated_at)
    new_rap_project = RapProjectLevel.new(
      name: name, rap_topic_level_id: topic_id,  created_at: created_at, updated_at: updated_at
    )
    new_rap_project.validate
    new_rap_project.errors
  end
  
  def validate_rap_task_level(name, project_id, created_at, updated_at)
    new_rap_task = RapTaskLevel.new(
      name: name, rap_project_level_id: project_id,  created_at: created_at, updated_at: updated_at
    )
    new_rap_task.validate
    new_rap_task.errors
  end
  
  def create_rap_program_level(name)
    new_rap_program = RapProgramLevel.new(name: name)
    new_rap_program.created_at = Time.now
    new_rap_program.updated_at = Time.now
    new_rap_program.save!
  end
  
  def create_rap_topic_level(name, program_id)
    new_rap_topic = RapTopicLevel.new(name: name, rap_program_level_id: program_id)
    new_rap_topic.created_at = Time.now
    new_rap_topic.updated_at = Time.now
    new_rap_topic.save!
  end
  
  def create_rap_project_level(name, topic_id)
    new_rap_project = RapProjectLevel.new(name: name, rap_topic_level_id: topic_id)
    new_rap_project.created_at = Time.now
    new_rap_project.updated_at = Time.now
    new_rap_project.save!
  end
  
  def create_rap_task_level(name, project_id)
    new_rap_task = RapTaskLevel.new(name: name, rap_project_level_id: project_id)
    new_rap_task.created_at = Time.now
    new_rap_task.updated_at = Time.now
    new_rap_task.save!
  end
  