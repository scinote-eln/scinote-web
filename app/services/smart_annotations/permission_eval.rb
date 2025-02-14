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
        Project.viewable_by_user(user, team).exists?(id: object.id)
      end

      def validate_exp_permissions(user, team, object)
        Experiment.viewable_by_user(user, team).exists?(id: object.id)
      end

      def validate_tsk_permissions(user, team, object)
        MyModule.viewable_by_user(user, team).exists?(id: object.id)
      end

      def validate_rep_item_permissions(user, team, object)
        if object.repository
          return Repository.viewable_by_user(user, team).find_by(id: object.repository_id).present? &&
                 can_read_repository?(user, object.repository)
        end

        # handles discarded repositories
        repository = Repository.with_discarded.find_by(id: object.repository_id)
        # evaluate to false if repository not found
        return false unless repository
      end
    end
  end
end
