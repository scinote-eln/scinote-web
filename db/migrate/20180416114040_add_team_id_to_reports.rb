class AddTeamIdToReports < ActiveRecord::Migration[5.1]
  def up
    add_reference :reports, :team, index: true
  end

  def down
    remove_column :reports, :team
  end
end
