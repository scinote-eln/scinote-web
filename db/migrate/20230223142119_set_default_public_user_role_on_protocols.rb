# frozen_string_literal: true

class SetDefaultPublicUserRoleOnProtocols < ActiveRecord::Migration[6.1]
  class TempProtocol < ApplicationRecord
    self.table_name = 'protocols'

    belongs_to :default_public_user_role, class_name: 'UserRole', optional: true
    attribute :visibility, :integer
    enum visibility: { hidden: 0, visible: 1 }
  end

  def change
    TempProtocol.visible.where(default_public_user_role_id: nil).update_all(
      default_public_user_role_id: UserRole.find_predefined_viewer_role.id
    )
  end
end
