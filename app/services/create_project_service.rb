# frozen_string_literal: true

class CreateProjectService
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
    return unless can_create_projects?(@user, @team)

=======
    new_project = nil
>>>>>>> Pulled latest release
    ActiveRecord::Base.transaction do
      @params[:created_by] = @user
      @params[:last_modified_by] = @user

<<<<<<< HEAD
      @project = @team.projects.create!(@params)
      create_project_activity
    end
    @project
=======
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
>>>>>>> Pulled latest release
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
