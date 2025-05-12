class AddTeamIdToReports < ActiveRecord::Migration[5.1]
  class TempReport < ApplicationRecord
    self.table_name = 'reports'
    belongs_to :project, foreign_key: :report_id
  end

  def up
    add_reference :reports, :team, index: true
    TempReport.preload(:project).find_each do |report|
      team_id = report.project.team_id
      report.update_column(:team_id, team_id)
    end
  end

  def down
    remove_column :reports, :team
  end
end
