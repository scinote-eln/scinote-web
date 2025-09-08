# frozen_string_literal: true

class AddSettingTeamColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :settings, :jsonb, default: {}, null: false

    # rubocop:disable Rails/SkipsModelValidations
    Team.find_each do |team|
      team.update_columns(settings: Extends::DEFAULT_TEAM_SETTINGS)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
