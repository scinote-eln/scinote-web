class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :organization_id, null: false
      t.string :message, null:false
    end
    add_foreign_key :logs, :organizations
  end
end
