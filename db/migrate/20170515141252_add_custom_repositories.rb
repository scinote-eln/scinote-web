class AddCustomRepositories < ActiveRecord::Migration[4.2]
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
      t.integer :created_by_id, null: false
      t.string :name
      t.integer :data_type, null: false
      t.timestamps null: true
    end

    add_foreign_key :repository_columns, :users, column: :created_by_id

    create_table :repository_rows do |t|
      t.belongs_to :repository, index: true
      t.integer :created_by_id, null: false
      t.integer :last_modified_by_id, null: false
      t.string :name, index: true
      t.timestamps null: true
    end

    add_foreign_key :repository_rows, :users, column: :created_by_id
    add_foreign_key :repository_rows, :users, column: :last_modified_by_id

    create_table :repository_cells do |t|
      t.belongs_to :repository_row, index: true
      t.belongs_to :repository_column, index: true
      t.references :value, polymorphic: true, index: true
      t.timestamps null: true
    end

    create_table :repository_date_values do |t|
      t.datetime :data
      t.timestamps null: true
      t.integer :created_by_id, null: false
      t.integer :last_modified_by_id, null: false
    end

    add_foreign_key :repository_date_values, :users, column: :created_by_id
    add_foreign_key :repository_date_values,
                    :users,
                    column: :last_modified_by_id

    create_table :repository_text_values do |t|
      t.string :data
      t.timestamps null: true
      t.integer :created_by_id, null: false
      t.integer :last_modified_by_id, null: false
    end

    add_foreign_key :repository_text_values, :users, column: :created_by_id
    add_foreign_key :repository_text_values,
                    :users,
                    column: :last_modified_by_id

    create_table :my_module_repository_rows do |t|
      t.integer :repository_row_id, index: true, null: false
      t.integer :my_module_id, null: :false
      t.integer :assigned_by_id, null: false
      t.timestamps null: true
      t.index %i(my_module_id repository_row_id),
              name: 'index_my_module_ids_repository_row_ids'
    end

    add_foreign_key :my_module_repository_rows, :users, column: :assigned_by_id

    create_table :repository_table_states do |t|
      t.jsonb :state, null: false
      t.references :user, index: true, null: false
      t.references :repository, index: true, null: false
      t.timestamps null: false
    end

    add_column :report_elements, :repository_id, :integer
    add_index :report_elements, :repository_id
  end
end
