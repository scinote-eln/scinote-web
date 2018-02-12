class CreateRepositoryListValues < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_list_items do |t|
      t.references :repository, index: true, foreign_key: true
      t.references :repository_column, index: true, foreign_key: true
      t.text :data, index: true, using: :gin, null: false
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :repository_list_values do |t|
      t.references :repository_list_item, index: true
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
