# frozen_string_literal: true

module UserAssignments
  class PropagateAssignmentJob < ApplicationJob
    queue_as :high_priority

    def perform(assignment, destroy: false, remove_from_team: false)
      @assignment = assignment
      @resource = assignment.assignable
      @destroy = destroy
      @remove_from_team = remove_from_team
      @type = assignment.class.model_name.param_key.gsub('_assignment', '').to_sym

      ActiveRecord::Base.transaction do
        @assignment.destroy! if destroy && !@assignment.destroyed?
        sync_resource_user_associations(@resource)
      end
    end

    private

    def sync_resource_user_associations(resource)
      # stop role update propagation for child resources when encountering a manual assignment
      return if resource != @resource && # child resource
                !@destroy &&
                resource.public_send(:"#{@type}_assignments").find_by(
                  "#{@type}_id" => @assignment.public_send(@type).id
                ).manually_assigned?

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
          destroy_or_update_assignment(child_association)
        else
          create_or_update_assignment(child_association)
        end

        sync_resource_user_associations(child_association)
      end

      destroy_or_update_assignment(resource) if resource.is_a?(Project) && @destroy
    end

    def create_or_update_assignment(resource)
      assignment =
        @assignment.class.find_or_initialize_by(
          "#{@type}_id": @assignment.public_send(@type).id,
          assignable: resource
        )

      return if assignment.manually_assigned?

      assignment.update!(
        user_role: @assignment.user_role,
        assigned_by: @assignment.assigned_by,
        assigned: :automatically
      )
    end

    def destroy_or_update_assignment(resource)
      # also destroy user designations if it's a MyModule
      resource.user_my_modules.where(user: @user).destroy_all if resource.is_a?(MyModule)

      assignment = resource.public_send(:"#{@type}_assignments").find_by(
        "#{@type}_id" => @assignment.public_send(@type).id
      )

      return unless assignment

      project = resource.is_a?(Project) ? resource : resource.project

      if project.default_public_user_role_id && !@remove_from_team
        # if project is public, the assignment
        # will reset to the default public role

        assignment.update!(
          user_role_id: project.default_public_user_role_id,
          assigned: :automatically,
          assigned_by: @assignment.assigned_by
        )
      else
        resource.favorites.where(user: @user).destroy_all if resource.respond_to?(:favorites)
        assignment.destroy!
      end
    end
  end
end
