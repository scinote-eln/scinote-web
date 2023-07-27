class DropDatatablesTeamsView < ActiveRecord::Migration[7.0]
  def change
    drop_view :datatables_teams
  end
end
