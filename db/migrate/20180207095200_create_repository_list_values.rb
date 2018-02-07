class CreateRepositoryListValues < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_list_values do |t|
      t.bigint :selected_item
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   oreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
