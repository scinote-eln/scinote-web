class AddWopi< ActiveRecord::Migration

  def up
   	add_column :users, :wopi_token, :string
    add_column :users, :wopi_token_ttl, :integer

    add_column :assets, :lock, :string, :limit => 1024
    add_column :assets, :lock_ttl, :integer
    add_column :assets, :version, :integer

    create_table :wopi_discoveries do |t|
      t.integer :expires, null: false
      t.string :proof_key_mod, null: false
      t.string :proof_key_exp, null: false
      t.string :proof_key_old_mod, null: false
      t.string :proof_key_old_exp, null: false
    end

    create_table :wopi_apps do |t|
      t.string :name, null: false
      t.string :icon, null: false
      t.integer :wopi_discovery_id, null: false
    end

    create_table :wopi_actions do |t|
      t.string :action, null: false
      t.string :extension, null: false
      t.string :urlsrc, null: false
      t.integer :wopi_app_id, null: false
    end

    add_foreign_key :wopi_actions, :wopi_apps, column: :wopi_app_id
    add_foreign_key :wopi_apps, :wopi_discoveries, column: :wopi_discovery_id

    add_index :wopi_actions, [:extension,:action]

  end

  def down
    remove_column :users, :wopi_token
    remove_column :users, :wopi_token_ttl

    remove_column :assets, :lock
    remove_column :assets, :lock_ttl
    remove_column :assets, :version

    drop_table :wopi_actions
    drop_table :wopi_apps
    drop_table :wopi_discoveries
  end
end
