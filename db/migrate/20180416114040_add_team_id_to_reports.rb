class AddTeamIdToReports < ActiveRecord::Migration[5.1]
  def up
    add_reference :reports, :team, index: true
    Report.preload(:project).find_each do |report|
      team_id = report.project.team_id
      report.update_column(:team_id, team_id)
    end
  end

  def down
    remove_column :reports, :team
  end
end
