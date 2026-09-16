class CreateEditingFlags < ActiveRecord::Migration[7.2]
  def change
    create_table :editing_flags do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamp :timeout_at
      t.references :subject, polymorphic: true, null: false

      t.timestamps
    end

    add_index :editing_flags, %i(user_id subject_type subject_id), unique: true
    add_index :editing_flags, :timeout_at
  end
end
