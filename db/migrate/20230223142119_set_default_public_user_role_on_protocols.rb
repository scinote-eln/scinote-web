# frozen_string_literal: true

class SetDefaultPublicUserRoleOnProtocols < ActiveRecord::Migration[6.1]
  def change
    Protocol.visible.where(default_public_user_role_id: nil).update_all(
      default_public_user_role_id: UserRole.find_predefined_viewer_role.id
    )
  end
end
