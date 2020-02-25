# frozen_string_literal: true

class CreateProjectService
  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
  end

  def call
    ActiveRecord::Base.transaction do
      @params[:visibility] ||= 'hidden'
      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @project = @team.projects.create!(@params)
      @project.user_projects.create!(role: :owner, user: @user)
      create_project_activity
      @project
    end
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
