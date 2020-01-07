class CreateZipExports < ActiveRecord::Migration[4.2]
  def change
    create_table :zip_exports do |t|
      t.references :user, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
