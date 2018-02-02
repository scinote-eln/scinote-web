class CreateStepComments < ActiveRecord::Migration[4.2]
  def change
    create_table :step_comments do |t|
      t.integer :step_id, null: false
      t.integer :comment_id, null: false
    end
    add_foreign_key :step_comments, :steps
    add_foreign_key :step_comments, :comments
    add_index :step_comments, [:step_id, :comment_id]
  end
end
