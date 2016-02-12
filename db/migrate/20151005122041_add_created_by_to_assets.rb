class AddCreatedByToAssets < ActiveRecord::Migration
  def change
    tables = [:assets, :checklists, :checklist_items, :my_module_groups, 
      :my_module_tags, :my_modules, :organizations, :projects,
       :sample_groups, :sample_types, :tables, :tags]

    tables.each do |table_name|
      add_column table_name, :created_by_id, :integer
      add_index table_name, :created_by_id
    end

    tables = [:assets, :checklists, :checklist_items, :comments, 
      :custom_fields, :my_modules, :organizations, :projects, 
      :reports, :results, :sample_groups, :sample_types, :samples,
      :steps, :tables, :tags]

    tables.each do |table_name|
      add_column table_name, :last_modified_by_id, :integer
      add_index table_name, :last_modified_by_id
    end

    tables = [:my_modules, :projects, :results]

    tables.each do |table_name|
      add_column table_name, :archived_by_id, :integer
      add_index table_name, :archived_by_id
      add_column table_name, :restored_by_id, :integer
      add_index table_name, :restored_by_id
      add_column table_name, :restored_on, :datetime
    end

    tables = [:sample_my_modules, :user_my_modules, 
      :user_organizations, :user_projects]
    tables.each do |table_name|
      add_column table_name, :assigned_by_id, :integer
      add_index table_name, :assigned_by_id
    end

    add_column :sample_my_modules, :assigned_on, :datetime
  end
end
