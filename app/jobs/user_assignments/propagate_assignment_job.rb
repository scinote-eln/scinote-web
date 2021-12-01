# frozen_string_literal: true

module UserAssignments
  class PropagateAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(resource, user, user_role, assigned_by, destroy: false)
      @user = user
      @user_role = user_role
      @assigned_by = assigned_by
      @destroy = destroy
      @resource = resource

      ActiveRecord::Base.transaction do
        sync_resource_user_associations(resource)
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
          destroy_user_assignment(child_association)
        else
          create_or_update_user_assignment(child_association)
        end

        sync_resource_user_associations(child_association)
      end
    end

    def create_or_update_user_assignment(object)
      user_assignment = UserAssignment.find_or_initialize_by(user: @user, assignable: object)
      return if user_assignment.manually_assigned?

      user_assignment.user_role = @user_role
      user_assignment.assigned_by = @assigned_by
      user_assignment.assigned = :automatically
      user_assignment.save!
    end

    def destroy_user_assignment(object)
      # also destroy user designations if it's a MyModule
      object.user_my_modules.where(user: @user).destroy_all if object.is_a?(MyModule)

      user_assignment = UserAssignment.find_by!(user: @user, assignable: object)

      if object.project.visible?
        # if project is public, the assignment
        # will reset to the default public role

        user_assignment.update!(
          user_role_id: object.project.default_public_user_role_id,
          assigned: :automatically,
          assigned_by: @assigned_by
        )
      else
        user_assignment.destroy!
      end
    end
  end
end
