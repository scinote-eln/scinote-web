class CreateDatatablesTeams < ActiveRecord::Migration[5.0]
  def change
    create_view :datatables_teams
  end
end
