# frozen_string_literal: true

module SmartAnnotations
  class PermissionEval
    class << self
      include Canaid::Helpers::PermissionsHelper

      def check(user, team, type, object)
        __send__("validate_#{type}_permissions", user, team, object)
      end

      private

      def validate_prj_permissions(user, team, object)
        object.archived = false
        permission_check = object.team.id == team.id && can_read_project?(user, object)
        object.archived = true if object.archived_changed?
        permission_check
      end

      def validate_exp_permissions(user, team, object)
        object.archived = false
        permission_check = object.project.team.id == team.id && can_read_experiment?(user, object)
        object.archived = true if object.archived_changed?
        permission_check
      end

      def validate_tsk_permissions(user, team, object)
        validate_exp_permissions(user, team, object.experiment)
      end

      def validate_rep_item_permissions(user, team, object)
        return can_read_repository?(user, object.repository) if object.repository

        # handles discarded repositories
        repository = Repository.with_discarded.find_by(id: object.repository_id)
        # evaluate to false if repository not found
        return false unless repository

        (repository.team.id == team.id ||
          repository.team_repositories.where(team_id: team.id).any?) &&
          can_read_repository?(user, repository)
      end
    end
  end
end
