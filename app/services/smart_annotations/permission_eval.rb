# frozen_string_literal: true

module SmartAnnotations
  class PermissionEval
    class << self
      include Canaid::Helpers::PermissionsHelper

      def check(user, type, object)
        __send__("validate_#{type}_permissions", user, object)
      end

      private

      def validate_prj_permissions(user, object)
        can_read_project?(user, object)
      end

      def validate_exp_permissions(user, object)
        can_read_experiment?(user, object)
      end

      def validate_tsk_permissions(user, object)
        can_read_my_module?(user, object)
      end

      def validate_rep_item_permissions(user, object)
        can_read_repository?(user, object.repository)
      end
    end
  end
end
