class CreateSamplesTables < ActiveRecord::Migration[4.2]
  def change
    create_table :samples_tables do |t|
      t.jsonb :status, null: false,
              default: if defined?(SampleDatatable)
                         SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE
                       else
                         {}
                       end
      # Foreign keys
      t.references :user, null: false
      t.references :team, null: false

      t.timestamps null: false
    end
    add_index :samples_tables, :user_id
    add_index :samples_tables, :team_id
  end
end
