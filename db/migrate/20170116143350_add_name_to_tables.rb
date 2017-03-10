class AddNameToTables < ActiveRecord::Migration
  def change
    add_column :tables, :name, :string, default: '', index: true
  end
end
