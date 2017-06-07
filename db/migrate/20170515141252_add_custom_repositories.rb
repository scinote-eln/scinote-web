class AddCustomRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.belongs_to :team, index: true
      t.integer :created_by_id, null: false
      t.string :name
      t.timestamps null: true
    end

    add_foreign_key :repositories, :users, column: :created_by_id

    create_table :repository_columns do |t|
      t.belongs_to :repository, index: true
      t.belongs_to :team, index: true
      t.integer :created_by_id, null: false
      t.string :name
      t.integer :data_type, null: false
      t.timestamps null: true
    end

    add_foreign_key :repository_columns, :users, column: :created_by_id

    create_table :repository_rows do |t|
      t.belongs_to :repository, index: true
      t.belongs_to :team, index: true
      t.integer :created_by_id, null: false
      t.string :name
      t.timestamps null: true
    end

    add_foreign_key :repository_rows, :users, column: :created_by_id

    create_table :repository_cells do |t|
      t.belongs_to :repository_row, index: true
      t.belongs_to :repository_column, index: true
      t.references :value, polymorphic: true, index: true
      t.timestamps null: true
    end

    create_table :repository_date_values do |t|
      t.datetime :value
      t.timestamps null: true
    end

    create_table :repository_text_values do |t|
      t.string :value
      t.timestamps null: true
    end
  end
end
