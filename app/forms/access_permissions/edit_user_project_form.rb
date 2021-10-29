# frozen_string_literal: true

module AccessPermissions
  class EditUserProjectForm
    include ActiveModel::Model

    attr_accessor :user, :project, :current_user

    def initialize(current_user, project)
      @project = project
      @current_user = current_user
    end

    def update(params)
      @user = project.users.find(params[:user_id])
      project_member = ProjectMember.new(user, project, current_user)
      project_member.user_role_id = params[:user_role_id]

      project_member.update
    end
  end
end
