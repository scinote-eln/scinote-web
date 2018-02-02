class CreateSettingsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.text :type, null: false
      t.jsonb :values, null: false, default: {}
    end
    add_index(:settings, :type, unique: true)
  end
end
