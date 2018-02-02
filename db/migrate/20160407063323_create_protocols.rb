class CreateProtocols < ActiveRecord::Migration[4.2]
  def up
    # First, create protocol table
    create_table :protocols do |t|
      t.string :name
      t.text :authors
      t.text :description
      t.integer :added_by_id
      t.integer :my_module_id
      t.integer :team_id, null: false
      t.integer :protocol_type, null: false, default: 0
      t.integer :parent_id
      t.datetime :parent_updated_at
      t.integer :archived_by_id
      t.datetime :archived_on
      t.integer :restored_by_id
      t.datetime :restored_on

      t.timestamps null: false
    end
    add_foreign_key :protocols, :users, column: :added_by_id
    add_foreign_key :protocols, :my_modules, column: :my_module_id
    add_foreign_key :protocols, :teams, column: :team_id
    add_foreign_key :protocols, :protocols, column: :parent_id
    add_foreign_key :protocols, :users, column: :archived_by_id
    add_foreign_key :protocols, :users, column: :restored_by_id
    add_index :protocols, :name
    add_index :protocols, :authors
    add_index :protocols, :description
    add_index :protocols, :added_by_id
    add_index :protocols, :my_module_id
    add_index :protocols, :team_id
    add_index :protocols, :parent_id
    add_index :protocols, :archived_by_id
    add_index :protocols, :restored_by_id

    # Also create keywords, this will be unused at the start
    create_table :protocol_keywords do |t|
      t.string :name
      t.timestamps null: false
    end
    add_index :protocol_keywords, :name

    # .. and the many-to-many association
    create_table :protocol_protocol_keywords do |t|
      t.integer :protocol_id, null: false
      t.integer :protocol_keyword_id, null: false
    end
    add_foreign_key :protocol_protocol_keywords, :protocols
    add_foreign_key :protocol_protocol_keywords, :protocol_keywords
    add_index :protocol_protocol_keywords, :protocol_id
    add_index :protocol_protocol_keywords, :protocol_keyword_id

    # Alright: now, the "real" data migration needs to happen
    add_column :steps, :protocol_id, :integer
    add_foreign_key :steps, :protocols, column: :protocol_id
    add_index :steps, :protocol_id

    MyModule.find_each do |my_module|
      protocol = Protocol.new(
        my_module_id: my_module.id,
        team_id: my_module.project.team.id,
        protocol_type: 0
      )
      protocol.save(validate: false)

      Step.where(my_module_id: my_module.id).find_each do |step|
        step.update_column(:protocol_id, protocol.id)
      end
    end

    remove_index :steps, column: :my_module_id
    remove_foreign_key :steps, :my_modules
    remove_column :steps, :my_module_id
    change_column_null :steps, :protocol_id, false
  end

  def down
    add_column :steps, :my_module_id, :integer
    add_foreign_key :steps, :my_modules
    add_index :steps, :my_module_id

    MyModule.find_each do |my_module|
      protocol = Protocol.where(my_module_id: my_module.id).first
      if protocol.present?
        Step.where(protocol_id: protocol.id).find_each do |step|
          step.update_column(:my_module_id, my_module.id)
        end
      end
    end

    remove_index :steps, column: :protocol_id
    remove_foreign_key :steps, :protocols
    remove_column :steps, :protocol_id

    # Simply drop the rest of the protocols
    # (the ones that are team-wide)

    remove_index :protocol_protocol_keywords, column: :protocol_id
    remove_index :protocol_protocol_keywords, column: :protocol_keyword_id
    remove_foreign_key :protocol_protocol_keywords, :protocols
    remove_foreign_key :protocol_protocol_keywords, :protocol_keywords
    drop_table :protocol_protocol_keywords

    remove_index :protocol_keywords, column: :name
    drop_table :protocol_keywords

    remove_index :protocols, column: :name
    remove_index :protocols, column: :authors
    remove_index :protocols, column: :description
    remove_index :protocols, column: :added_by_id
    remove_index :protocols, column: :my_module_id
    remove_index :protocols, column: :team_id
    remove_index :protocols, column: :parent_id
    remove_index :protocols, column: :archived_by_id
    remove_index :protocols, column: :restored_by_id
    remove_foreign_key :protocols, column: :added_by_id
    remove_foreign_key :protocols, :my_modules
    remove_foreign_key :protocols, :teams
    remove_foreign_key :protocols, column: :parent_id
    remove_foreign_key :protocols, column: :archived_by_id
    remove_foreign_key :protocols, column: :restored_by_id
    drop_table :protocols
  end
end
