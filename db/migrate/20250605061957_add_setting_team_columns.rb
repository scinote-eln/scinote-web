# frozen_string_literal: true

class AddSettingTeamColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :settings, :jsonb, default: Extends::DEFAULT_TEAM_SETTINGS, null: false
  end
end
