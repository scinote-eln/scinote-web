class AddNameToTables < ActiveRecord::Migration[4.2]
  def change
    add_column :tables, :name, :string, default: '', index: true
  end
end
