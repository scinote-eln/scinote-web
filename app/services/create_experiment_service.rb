# frozen_string_literal: true

class CreateExperimentService
  include Canaid::Helpers::PermissionsHelper

  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
  end

  def call
    ActiveRecord::Base.transaction do
      unless @params[:project].instance_of?(Project)
        @params[:project] = CreateProjectService.new(@user, @team, @params[:project]).call
      end

      raise ActiveRecord::Rollback unless @params[:project]&.valid? &&
                                          can_create_project_experiments?(@user, @params[:project])

      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @experiment = @params[:project].experiments.create!(@params)
      create_experiment_activity
    end
    @experiment
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
