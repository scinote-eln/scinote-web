# frozen_string_literal: true

module AccessPermissions
  class NewUserProjectForm
    include ActiveModel::Model

    attr_accessor :project, :resource_members
    attr_reader :current_user, :new_members_count

    def initialize(current_user, project, attributes = {})
      @project = project
      @users = attributes[:users]
      @current_user = current_user
      set_default_resource_members if @users
      @error = false
      @new_members_count = 0
    end

    def save
      if @error
        false
      else
        @resource_members.map(&:create)
        true
      end
    end

    def resource_members=(attributes)
      @resource_members ||= []
      attributes.fetch(:resource_members).each do |_, resource_member|
        user = User.find(resource_member[:user_id])
        project_member = ProjectMember.new(user, @project, current_user)
        project_member.assign = resource_member[:assign]
        project_member.user_role_id = resource_member[:user_role_id]
        @error = true unless project_member.valid?
        @new_members_count += 1 if project_member.assign
        @resource_members << project_member
      end
    end

    private

    def set_default_resource_members
      @resource_members = @users.order(:full_name).map { |u| ProjectMember.new(u, @project, current_user) }
    end
  end
end
