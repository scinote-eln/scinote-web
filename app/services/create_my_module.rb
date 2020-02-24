# frozen_string_literal: true

class CreateMyModule
  include Canaid::Helpers::PermissionsHelper

  # config example: {project_id: 5, experiment_name: 'New Experiment', my_module_name: 'New Task'}

  def initialize(user, team, config)
    @config = config
    @user = user
    @team = team
  end

  def call
    ActiveRecord::Base.transaction do
      @project = load_project
      @experiment = load_experiment
      raise ActiveRecord::Rollback unless @project && @experiment && can_manage_experiment?(@user, @experiment)

      my_module_params = {
        x: 0,
        y: 0,
        name: @config[:my_module_name] || 'New Task'
      }

      my_module = @experiment.my_modules.new(my_module_params)
      new_pos = my_module.get_new_position
      my_module.x = new_pos[:x]
      my_module.y = new_pos[:y]

      if my_module.save
        create_my_module_activity(my_module)
        return my_module
      end

      raise ActiveRecord::Rollback
    end
  end

  private

  def load_project
    if @config[:project_id]
      @team.projects.find_by(id: @config[:project_id])
    elsif @config[:project_name]
      return false unless can_create_projects?(@user, @team)

      project_params = {
        name: @config[:project_name],
        team: @team,
        visibility: 'hidden',
        created_by: @user,
        last_modified_by: @user
      }

      project = @team.projects.new(project_params)

      if project.save
        UserProject.create(role: :owner, user: @user, project: project)
        create_project_activity(project)
        project
      end
    end
  end

  def load_experiment
    return false unless @project

    if @config[:experiment_id]
      @project.experiments.find_by(id: @config[:experiment_id])
    elsif @config[:experiment_name]
      return false unless can_create_experiments?(@user, @project)

      experiment_params = {
        name: @config[:experiment_name],
        project: @project,
        created_by: @user,
        last_modified_by: @user
      }

      experiment = @project.experiments.new(experiment_params)

      if experiment.save
        create_experiment_activity(experiment)
        experiment
      end
    end
  end

  def create_project_activity(project)
    Activities::CreateActivityService
      .call(activity_type: :create_project,
            owner: @user,
            subject: project,
            team: @team,
            project: project,
            message_items: { project: project.id })
  end

  def create_experiment_activity(experiment)
    Activities::CreateActivityService
      .call(activity_type: :create_experiment,
            owner: @user,
            subject: experiment,
            team: @team,
            project: experiment.project,
            message_items: { experiment: experiment.id })
  end

  def create_my_module_activity(my_module)
    Activities::CreateActivityService
      .call(activity_type: :create_module,
            owner: @user,
            team: @team,
            project: @project,
            subject: my_module,
            message_items: { my_module: my_module.id })
  end
end
