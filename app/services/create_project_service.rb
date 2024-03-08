# frozen_string_literal: true

class CreateProjectService
  include Canaid::Helpers::PermissionsHelper
  attr_reader :errors

  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
    @errors = {}
  end

  def call
    return unless can_create_projects?(@user, @team)

    ActiveRecord::Base.transaction do
      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @project = @team.projects.build(@params)
      @project.default_public_user_role ||= UserRole.find_predefined_viewer_role if @project.visible?
      @project.save!

      create_project_activity
    rescue ActiveRecord::RecordInvalid
      @errors['project'] = @project.errors.messages
    end
    @project
  end

  private

  def create_project_activity
    Activities::CreateActivityService
      .call(activity_type: :create_project,
            owner: @user,
            subject: @project,
            team: @team,
            project: @project,
            message_items: { project: @project.id })
  end
end
