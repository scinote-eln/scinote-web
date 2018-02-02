class AddForeignKeysToTables < ActiveRecord::Migration[4.2]
  def change
    tables = [:assets, :checklists, :checklist_items, :my_module_groups,
      :my_module_tags, :my_modules, :teams, :projects,
       :sample_groups, :sample_types, :tables, :tags]

    tables.each do |table_name|
      add_foreign_key table_name, :users, column: :created_by_id
    end

    tables = [:assets, :checklists, :checklist_items, :comments,
      :custom_fields, :my_modules, :teams, :projects,
      :reports, :results, :sample_groups, :sample_types, :samples,
      :steps, :tables, :tags]

    tables.each do |table_name|
      add_foreign_key table_name, :users, column: :last_modified_by_id
    end

    tables = [:my_modules, :projects, :results]

    tables.each do |table_name|
      add_foreign_key table_name, :users, column: :archived_by_id
      add_foreign_key table_name, :users, column: :restored_by_id
    end

    tables = [:sample_my_modules, :user_my_modules,
      :user_teams, :user_projects]
    tables.each do |table_name|
      add_foreign_key table_name, :users, column: :assigned_by_id
    end
  end

end
