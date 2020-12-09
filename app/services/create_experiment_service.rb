# frozen_string_literal: true

class CreateExperimentService
<<<<<<< HEAD
  include Canaid::Helpers::PermissionsHelper

=======
>>>>>>> Pulled latest release
  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
  end

  def call
<<<<<<< HEAD
    ActiveRecord::Base.transaction do
      unless @params[:project].instance_of?(Project)
        @params[:project] = CreateProjectService.new(@user, @team, @params[:project]).call
      end

      raise ActiveRecord::Rollback unless @params[:project]&.valid? &&
                                          can_create_project_experiments?(@user, @params[:project])
=======
    new_experiment = nil
    ActiveRecord::Base.transaction do
      unless @params[:project].class == Project
        @params[:project] = CreateProjectService.new(@user, @team, @params[:project]).call
      end
      unless @params[:project]&.errors&.empty?
        new_experiment = @params[:project]
        raise ActiveRecord::Rollback
      end
>>>>>>> Pulled latest release

      @params[:created_by] = @user
      @params[:last_modified_by] = @user

<<<<<<< HEAD
      @experiment = @params[:project].experiments.create!(@params)
      create_experiment_activity
    end
    @experiment
=======
      @experiment = @params[:project].experiments.new(@params)

      create_experiment_activity if @experiment.save

      new_experiment = @experiment
    end
    new_experiment
>>>>>>> Pulled latest release
  end

  private

  def create_experiment_activity
    Activities::CreateActivityService
      .call(activity_type: :create_experiment,
            owner: @user,
            subject: @experiment,
            team: @team,
            project: @experiment.project,
            message_items: { experiment: @experiment.id })
  end
end
