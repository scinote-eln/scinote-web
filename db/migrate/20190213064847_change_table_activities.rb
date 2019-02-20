# frozen_string_literal: true

class ChangeTableActivities < ActiveRecord::Migration[5.1]
  def change
    add_reference :activities, :subject, polymorphic: true, index: true
    add_reference :activities, :team, index: true
    add_column :activities, :group_type, :integer
    rename_column :activities, :user_id, :owner_id
    add_column :activities, :values, :json
    change_column_null :activities, :message, :string, true
  end
end
