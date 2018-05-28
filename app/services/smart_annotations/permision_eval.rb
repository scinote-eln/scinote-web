# frozen_string_literal: true

module SmartAnnotations
  class PermissionEval
    class << self
      include Canaid::Helpers::PermissionsHelper

      def check(user, type, object)
        send("validate_#{type}_permissions", user, object)
      end

      private

      def validate_prj_permissions(user, object)
        can_read_project?(user, object)
      end

      def validate_exp_permissions(user, object)
        can_read_experiment?(user, object)
      end

      def validate_tsk_permissions(user, object)
        can_read_experiment?(user, object.experiment)
      end

      def validate_rep_item_permissions(user, object)
        return can_read_team?(user, object.repository.team) if object.repository
        # handles discarded repositories
        repository = Repository.with_discarded.find_by_id(object.repository_id)
        # evaluate to false if repository not found
        return false unless repository
        can_read_team?(user, repository.team)
      end
    end
  end
end
