class CreateRepositoryListValues < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_list_values do |t|
      t.bigint :selected_item
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :repository_list_items do |t|
      t.references :repository_list_value, foreign_key: true
      t.text :name, index: true, using: :gin, null: false
      t.timestamps
    end
  end
end
