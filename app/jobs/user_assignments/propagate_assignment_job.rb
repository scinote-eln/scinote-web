# frozen_string_literal: true

module UserAssignments
  class PropagateAssignmentJob < ApplicationJob
    include Canaid::Helpers::PermissionsHelper

    queue_as :high_priority

    def perform(assignment, destroy: false, remove_from_team: false)
      @assignment = assignment
      @resource = assignment.assignable
      @destroy = destroy
      @remove_from_team = remove_from_team
      @type = assignment.class.model_name.param_key.gsub('_assignment', '').to_sym

      @assignment.with_lock do
        @assignment.destroy! if destroy && !@assignment.destroyed?
        cleanup!(@assignment)
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
          destroy_assignment(child_association)
        else
          create_or_update_assignment(child_association)
        end

        sync_resource_user_associations(child_association)
      end

      destroy_assignment(resource) if resource.is_a?(Project) && @destroy
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

    def destroy_assignment(resource)
      assignment = resource.public_send(:"#{@type}_assignments").find_by(
        "#{@type}_id" => @assignment.public_send(@type).id
      )

      return unless assignment

      assignment.destroy!

      cleanup!(assignment)
    end

    def cleanup!(assignment)
      # clean up designations and favorites if user is no longer assigned
      assigned_users = assignment.assignable.users

      assignment.assignable.favorites.where.not(user: assigned_users).destroy_all if assignment.assignable.respond_to?(:favorites)
      assignment.assignable.user_my_modules.where.not(user: assigned_users).destroy_all if assignment.assignable.is_a?(MyModule)
    end
  end
end
