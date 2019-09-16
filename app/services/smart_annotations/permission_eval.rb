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
        object.team.id == team.id && can_read_project?(user, object)
      end

      def validate_exp_permissions(user, team, object)
        object.project.team.id == team.id && can_read_experiment?(user, object)
      end

      def validate_tsk_permissions(user, team, object)
        object.experiment.project.team.id == team.id &&
          can_read_experiment?(user, object.experiment)
      end

      def validate_rep_item_permissions(user, team, object)
        if object.repository
          return can_read_repository?(user, object.repository)
        end

        # handles discarded repositories
        repository = Repository.with_discarded.find_by_id(object.repository_id)
        # evaluate to false if repository not found
        return false unless repository

        (repository.team.id == team.id ||
          repository.team_repositories.where(team_id: team.id).any?) &&
          can_read_repository?(user, repository)
      end
    end
  end
end
