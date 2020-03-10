# frozen_string_literal: true

class CreateProjectService
  def initialize(user, team, params)
    @params = params
    @user = user
    @team = team
  end

  def call
    new_project = nil
    ActiveRecord::Base.transaction do
      @params[:created_by] = @user
      @params[:last_modified_by] = @user

      @project = @team.projects.new(@params)

      if @project.save
        @project.user_projects.create!(role: :owner, user: @user)
        create_project_activity
        new_project = @project
      else
        new_project = @project
        raise ActiveRecord::Rollback

      end
    end
    new_project
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
