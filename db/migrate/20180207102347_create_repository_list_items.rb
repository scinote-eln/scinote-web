class CreateRepositoryListItems < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_list_items do |t|
      t.references :repository_list_value, foreign_key: true
      t.text :name, index: true, using: :gin, null: false
      t.timestamps
    end
  end
end
