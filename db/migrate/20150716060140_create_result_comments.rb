class CreateResultComments < ActiveRecord::Migration[4.2]
  def change
    create_table :result_comments do |t|
      t.integer :result_id, null: false
      t.integer :comment_id, null: false
    end
    add_foreign_key :result_comments, :results
    add_index :result_comments, [:result_id, :comment_id]
  end
end
