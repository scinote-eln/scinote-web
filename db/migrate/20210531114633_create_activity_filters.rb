class CreateActivityFilters < ActiveRecord::Migration[4.2]
  def change
    create_table :activity_filters do |t|
      t.string :name, null: false
      t.jsonb :filter, null: false

      t.timestamps null: false
    end
  end
end
