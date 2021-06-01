# frozen_string_literal: true

class AddDefaultSettingsToOldReports < ActiveRecord::Migration[6.1]
  def change
    Report.find_each do |report|
      report.update!(settings: Report::DEFAULT_SETTINGS)
    end
  end
end
