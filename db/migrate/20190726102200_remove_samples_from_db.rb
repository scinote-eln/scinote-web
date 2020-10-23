# frozen_string_literal: true

class RemoveSamplesFromDb < ActiveRecord::Migration[6.0]
  def change
    # Revert 20171003082333_add_connections_and_sample_tasks_indexes
    remove_index :sample_my_modules, :my_module_id

    # Revert 20170407082423_update_indexes_for_faster_search
    remove_index :samples, name: :index_samples_on_name if index_exists?(:samples, :index_samples_on_name)
    remove_index :samples, name: :index_sample_types_on_name if index_exists?(:samples, :index_sample_types_on_name)
    remove_index :samples, name: :index_sample_groups_on_name if index_exists?(:samples, :index_sample_groups_on_name)
    remove_index :samples, name: :index_sample_custom_fields_on_value if index_exists?(:samples, :index_sample_custom_fields_on_value)

    # Revert 20161123161514_create_samples_tables
    remove_index :samples_tables, :user_id
    remove_index :samples_tables, :team_id
    drop_table :samples_tables

    # Revert 20151215103642_add_foreign_keys_to_tables
    remove_foreign_key :custom_fields, column: :last_modified_by_id

    # Revert 20151028091615_add_counter_cache_to_samples
    remove_column :samples, :nr_of_modules_assigned_to, :integer, default: 0
    remove_column :my_modules, :nr_of_assigned_samples, :integer, default: 0

    # Revert 20151005122041_add_created_by_to_assets
    remove_column :sample_my_modules, :assigned_on, :datetime

    # Revert 20150827130822_create_sample_custom_fields
    remove_index :sample_custom_fields, :custom_field_id
    remove_index :sample_custom_fields, :sample_id
    remove_foreign_key :sample_custom_fields, :custom_fields
    remove_foreign_key :sample_custom_fields, :samples
    drop_table :sample_custom_fields

    # Revert 20150827130647_create_custom_fields
    remove_index :custom_fields, :user_id
    remove_index :custom_fields, :team_id
    remove_foreign_key :custom_fields, :users
    remove_foreign_key :custom_fields, :teams
    drop_table :custom_fields

    # Revert 20150820124022_add_default_columns_to_samples
    remove_index :samples, :sample_group_id
    remove_index :samples, :sample_type_id
    remove_foreign_key :samples, :sample_groups
    remove_foreign_key :samples, :sample_types
    remove_column :samples, :sample_group_id, :integer
    remove_column :samples, :sample_type_id, :integer

    # Revert 20150820123018_create_sample_types
    remove_index :sample_types, :team_id
    remove_foreign_key :sample_types, :teams
    drop_table :sample_types

    # Revert 20150820120553_create_sample_groups
    remove_index :sample_groups, :team_id
    remove_foreign_key :sample_groups, :teams
    drop_table :sample_groups

    # Revert 20150716120130_create_sample_my_modules
    remove_index :sample_my_modules, %i(sample_id my_module_id)
    remove_foreign_key :sample_my_modules, :samples
    remove_foreign_key :sample_my_modules, :my_modules
    drop_table :sample_my_modules

    # Revert 20150716062801_create_samples
    remove_index :samples, :user_id
    remove_index :samples, :team_id
    remove_foreign_key :samples, :users
    remove_foreign_key :samples, :teams
    drop_table :samples
  end
end
