class CreateSampleComments < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_comments do |t|
      t.integer :sample_id, null: false
      t.integer :comment_id, null: false
    end
    add_foreign_key :sample_comments, :samples
    add_foreign_key :sample_comments, :comments
    add_index :sample_comments, [:sample_id, :comment_id]
  end
end
