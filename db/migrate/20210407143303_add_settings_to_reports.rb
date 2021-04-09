# frozen_string_literal: true

class AddSettingsToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :settings, :jsonb, default: {}, null: false
  end
end
