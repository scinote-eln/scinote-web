# frozen_string_literal: true

module UserAssignments
  class PropagateAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(resource, target_id, user_role, assigned_by_id, options = {})
      @sync_group = options[:group] || false
      @destroy = options[:destroy] || false
      @remove_from_team = options[:remove_from_team] || false
      @user_role = user_role
      @assigned_by = User.find_by(id: assigned_by_id)
      @resource = resource

      if @sync_group
        team_id = options.fetch(:team_id)
        @team = Team.find(team_id)
        @user_group = @team.user_groups.find(target_id)
      else
        @user = User.find(target_id)
      end

      ActiveRecord::Base.transaction do
        if @sync_group
          sync_resource_user_group_associations(@resource)
        else
          sync_resource_user_associations(@resource)
        end
      end
    end

    private

    def sync_resource_user_associations(resource)
      # stop role update propagation for child resources when encountering a manual assignment
      return if resource != @resource && # child resource
                !@destroy &&
                resource.user_assignments.find_by(user: @user).manually_assigned?

      child_associations =
        case resource
        when Project
          resource.experiments
        when Experiment
          resource.my_modules
        else
          return
        end

      child_associations.find_each do |child_association|
        if @destroy
          destroy_or_update_user_assignment(child_association)
        else
          create_or_update_user_assignment(child_association)
        end

        sync_resource_user_associations(child_association)
      end

      destroy_or_update_user_assignment(resource) if resource.is_a?(Project) && @destroy
    end

    def create_or_update_user_assignment(object)
      user_assignment = UserAssignment.find_or_initialize_by(user: @user, assignable: object)
      return if user_assignment.manually_assigned?

      user_assignment.user_role = @user_role
      user_assignment.assigned_by = @assigned_by
      user_assignment.assigned = :automatically
      user_assignment.save!
    end

    def destroy_or_update_user_assignment(object)
      # also destroy user designations if it's a MyModule
      object.user_my_modules.where(user: @user).destroy_all if object.is_a?(MyModule)

      user_assignment = object.user_assignments.find { |ua| ua.user_id == @user.id }
      return if user_assignment.blank?

      project = object.is_a?(Project) ? object : object.project

      if project.visible? && !@remove_from_team
        # if project is public, the assignment
        # will reset to the default public role

        user_assignment.update!(
          user_role_id: project.default_public_user_role_id,
          assigned: :automatically,
          assigned_by: @assigned_by
        )
      else
        object.favorites.where(user: @user).destroy_all if object.respond_to?(:favorites)
        user_assignment.destroy!
      end
    end

    def sync_resource_user_group_associations(resource)
      # stop role update propagation for child resources when encountering a manual assignment
      return if resource != @resource && # child resource
                !@destroy &&
                resource.user_group_assignments.find_by(user_group: @user_group).manually_assigned?

      child_associations =
        case resource
        when Project
          resource.experiments
        when Experiment
          resource.my_modules
        else
          return
        end

      child_associations.find_each do |child_association|
        if @destroy
          destroy_user_group_assignment(child_association)
        else
          create_or_update_user_group_assignment(child_association)
        end

        sync_resource_user_group_associations(child_association)
      end

      destroy_user_group_assignment(resource) if resource.is_a?(Project) && @destroy
    end

    def create_or_update_user_group_assignment(object)
      user_group_assignment = UserGroupAssignment.find_or_initialize_by(user_group: @user_group, assignable: object, team: @team)
      return if user_group_assignment.manually_assigned?

      user_group_assignment.user_role = @user_role
      user_group_assignment.assigned_by = @assigned_by
      user_group_assignment.assigned = :automatically
      user_group_assignment.save!
    end

    def destroy_user_group_assignment(object)
      user_group_assignment = object.user_group_assignments.find { |ua| ua.user_group_id == @user_group.id }
      return if user_group_assignment.blank?

      user_group_assignment.destroy!
    end
  end
end
