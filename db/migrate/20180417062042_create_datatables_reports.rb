class CreateDatatablesReports < ActiveRecord::Migration[5.1]
  def change
    create_view :datatables_reports, materialized: true
    add_index :datatables_reports, :id, unique: true
    add_index :datatables_reports, :team_id
  end
end
