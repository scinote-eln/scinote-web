class DeleteSamplesAndAssociatedModels < ActiveRecord::Migration[5.1]
  def up
    drop_table :samples_tables
    drop_table :sample_custom_fields
    drop_table :sample_my_modules
    drop_table :samples
    drop_table :sample_types
    drop_table :sample_groups
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
    create_table :sample_groups do |t|
      t.string :name, null: false
      t.string :color, null: false, default: '#ff0000'
      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_groups, :teams
    add_index :sample_groups, :team_id

    create_table :sample_types do |t|
      t.string :name, null: false
      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :sample_types, :teams
    add_index :sample_types, :team_id

    create_table :samples do |t|
      t.string :name, null: false
      # Foreign keys
      t.integer :user_id, null: false
      t.integer :team_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :samples, :users
    add_foreign_key :samples, :teams
    add_index :samples, :user_id
    add_index :samples, :team_id

    create_table :sample_my_modules do |t|
      t.integer :sample_id, null: false
      t.integer :my_module_id, null: false
    end
    add_foreign_key :sample_my_modules, :samples
    add_foreign_key :sample_my_modules, :my_modules
    add_index :sample_my_modules, [:sample_id, :my_module_id]

    create_table :sample_custom_fields do |t|
      t.string :value, null: false
      t.integer :custom_field_id, null: false
      t.integer :sample_id, null: :false
      t.timestamps null: false
    end
    add_foreign_key :sample_custom_fields, :custom_fields
    add_foreign_key :sample_custom_fields, :samples
    add_index :sample_custom_fields, :custom_field_id
    add_index :sample_custom_fields, :sample_id

    create_table :samples_tables do |t|
      t.jsonb :status, null: false,
              default: SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE
      # Foreign keys
      t.references :user, null: false
      t.references :team, null: false
      t.timestamps null: false
    end
    add_index :samples_tables, :user_id
    add_index :samples_tables, :team_id
    User.find_each do |user|
      next unless user.teams
      user.teams.find_each do |team|
        team_status = SampleDatatable::SAMPLES_TABLE_DEFAULT_STATE.deep_dup
        next unless team.custom_fields
        team.custom_fields.each_with_index do |_, index|
          team_status['columns'] << { 'visible' => true,
                                      'search' => {
                                        'search' => '',
                                        'smart' => true,
                                        'regex' => false,
                                        'caseInsensitive' => true
                                      } }
          team_status['ColReorder'] << (7 + index)
        end
        SamplesTable.create(user: user, team: team, status: team_status)
      end
    end
  end
end
