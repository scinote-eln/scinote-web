class CreateProjectComments < ActiveRecord::Migration[4.2]
  def change
    create_table :project_comments do |t|
      t.integer :project_id, null: false
      t.integer :comment_id, null: false
    end
    add_foreign_key :project_comments, :projects
    add_index :project_comments, [:project_id, :comment_id]
  end
end
