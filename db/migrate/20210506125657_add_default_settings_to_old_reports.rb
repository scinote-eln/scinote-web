# frozen_string_literal: true

class AddDefaultSettingsToOldReports < ActiveRecord::Migration[6.1]
  class TempReport < ApplicationRecord
    self.table_name = 'reports'
  end

  def change
    TempReport.find_each do |report|
      report.update!(settings: Report::DEFAULT_SETTINGS)
    end
  end
end
