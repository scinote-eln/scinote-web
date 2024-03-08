# frozen_string_literal: true

class CreateExperimentService
  include Canaid::Helpers::PermissionsHelper
  attr_reader :errors

  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
    @errors = {}
  end

  def call
    ActiveRecord::Base.transaction do
      unless @params[:project].instance_of?(Project)
        project_service = CreateProjectService.new(@user, @team, @params[:project])
        @params[:project] = project_service.call
      end

      raise ActiveRecord::RecordInvalid unless @params[:project]&.valid? &&
                                          can_create_project_experiments?(@user, @params[:project])

      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @experiment = @params[:project].experiments.build(@params)
      @experiment.save!
      create_experiment_activity
    rescue ActiveRecord::RecordInvalid
      @errors['experiment'] = @experiment.errors.messages if @experiment
      @errors.merge!(project_service.errors) if project_service&.errors&.any?
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
