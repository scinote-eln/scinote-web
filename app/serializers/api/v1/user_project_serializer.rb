# frozen_string_literal: true

module Api
  module V1
    class UserProjectSerializer < ActiveModel::Serializer
      include UserRolesHelper

      type :user_projects
      attributes :id, :role

      belongs_to :user, serializer: UserSerializer

      def role
        # TODO: sync about the role solution
        user_role = object.project
                          .user_assignments
                          .select { |ua| ua.user_id == object.user.id }
                          .first&.user_role
        return unless user_role
        legacy_user_role_parser(user_role.name)
      end
    end
  end
end
