# frozen_string_literal: true

class SelectStepTextsInReports < ActiveRecord::Migration[6.1]
  class TempReport < ApplicationRecord
    self.table_name = 'reports'
  end

  def change
    TempReport.find_each do |report|
      next unless report.settings.dig('task', 'protocol')

      report.settings['task']['protocol']['step_texts'] = true
      report.save!
    end
  end
end
