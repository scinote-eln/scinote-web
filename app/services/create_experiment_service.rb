# frozen_string_literal: true

class CreateExperimentService
  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
  end

  def call
    new_experiment = nil
    ActiveRecord::Base.transaction do
      unless @params[:project].class == Project
        @params[:project] = CreateProjectService.new(@user, @team, @params[:project]).call
      end
      unless @params[:project]&.errors&.empty?
        new_experiment = @params[:project]
        raise ActiveRecord::Rollback
      end

      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @experiment = @params[:project].experiments.new(@params)

      create_experiment_activity if @experiment.save

      new_experiment = @experiment
    end
    new_experiment
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
