class CreateResultTexts < ActiveRecord::Migration[4.2]
  def change
    create_table :result_texts do |t|
      t.string :text, null: false
      t.integer :result_id, null: false
    end
    add_foreign_key :result_texts, :results
    add_index :result_texts, :result_id
  end
end
