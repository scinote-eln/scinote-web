require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class UpdateIndexesForFasterSearch < ActiveRecord::Migration
  def up
    if db_adapter_is? 'PostgreSQL'
      # Removing old indexes
      remove_index :projects, :name if index_exists?(:projects, :name)
      remove_index :my_modules, :name if index_exists?(:my_modules, :name)
      if index_exists?(:my_modules, :description)
        remove_index :my_modules, :description
      end
      remove_index :protocols, :name if index_exists?(:protocols, :name)
      if index_exists?(:protocols, :description)
        remove_index :protocols, :description
      end
      remove_index :protocols, :authors if index_exists?(:protocols, :authors)
      if index_exists?(:protocol_keywords, :name)
        remove_index :protocol_keywords, :name
      end
      if index_exists?(:my_module_groups, :name)
        remove_index :my_module_groups, :name
      end
      remove_index :tags, :name if index_exists?(:tags, :name)
      remove_index :results, :name if index_exists?(:results, :name)
      remove_index :result_texts, :text if index_exists?(:result_texts, :text)
      remove_index :reports, :name if index_exists?(:reports, :name)
      if index_exists?(:reports, :description)
        remove_index :reports, :description
      end
      if index_exists?(:assets, :file_file_name)
        remove_index :assets, :file_file_name
      end
      remove_index :samples, :name if index_exists?(:samples, :name)
      remove_index :sample_types, :name if index_exists?(:sample_types, :name)
      remove_index :sample_groups, :name if index_exists?(:sample_groups, :name)
      if index_exists?(:sample_custom_fields, :value)
        remove_index :sample_custom_fields, :value
      end
      remove_index :steps, :name if index_exists?(:steps, :name)
      remove_index :steps, :description if index_exists?(:steps, :description)
      remove_index :checklists, :name if index_exists?(:checklists, :name)
      if index_exists?(:checklist_items, :text)
        remove_index :checklist_items, :text
      end
      remove_index :tables, :name if index_exists?(:tables, :name)
      remove_index :users, :full_name if index_exists?(:users, :full_name)
      remove_index :comments, :message if index_exists?(:comments, :message)
      remove_index :comments, :type if index_exists?(:comments, :type)
      if index_exists?(:protocols, :protocol_type)
        remove_index :protocols, :protocol_type
      end
      remove_index :checklists, :step_id if index_exists?(:checklists, :step_id)

      execute(
        "CREATE OR REPLACE FUNCTION
          trim_html_tags(IN input TEXT, OUT output TEXT) AS $$
        SELECT regexp_replace(input,
          E'<[^>]*>|\\\\[#.*\\\\]|\\\\[@.*\\\\]',
          '',
          'g');
        $$ LANGUAGE SQL;"
      )

      add_gin_index_without_tags :projects, :name
      add_gin_index_without_tags :my_modules, :name
      add_gin_index_without_tags :my_module_groups, :name
      add_gin_index_without_tags :my_modules, :description
      add_gin_index_without_tags :protocols, :name
      add_gin_index_without_tags :protocols, :description
      add_gin_index_without_tags :protocols, :authors
      add_gin_index_without_tags :protocol_keywords, :name
      add_gin_index_without_tags :tags, :name
      add_gin_index_without_tags :results, :name
      add_gin_index_without_tags :result_texts, :text
      add_gin_index_without_tags :reports, :name
      add_gin_index_without_tags :reports, :description
      add_gin_index_without_tags :assets, :file_file_name
      add_gin_index_without_tags :samples, :name
      add_gin_index_without_tags :sample_types, :name
      add_gin_index_without_tags :sample_groups, :name
      add_gin_index_without_tags :sample_custom_fields, :value
      add_gin_index_without_tags :steps, :name
      add_gin_index_without_tags :steps, :description
      add_gin_index_without_tags :checklists, :name
      add_gin_index_without_tags :checklist_items, :text
      add_gin_index_without_tags :tables, :name
      add_gin_index_without_tags :users, :full_name
      add_gin_index_without_tags :comments, :message
      add_index :comments, :type
      add_index :protocols, :protocol_type
      add_index :checklists, :step_id
    end
  end

  def down
    # remove_index :steps, :team_id
    # remove_column :steps, :team_id, :integer

    if db_adapter_is? 'PostgreSQL'
      remove_index :projects, :name
      remove_index :my_modules, :name
      remove_index :my_modules, :description
      remove_index :my_module_groups, :name
      remove_index :protocols, :name
      remove_index :protocols, :description
      remove_index :protocols, :authors
      remove_index :protocol_keywords, :name
      remove_index :tags, :name
      remove_index :results, :name
      remove_index :result_texts, :text
      remove_index :reports, :name
      remove_index :reports, :description
      remove_index :assets, :file_file_name
      remove_index :samples, :name
      remove_index :sample_types, :name
      remove_index :sample_groups, :name
      remove_index :sample_custom_fields, :value
      remove_index :steps, :name
      remove_index :steps, :description
      remove_index :checklists, :name
      remove_index :checklist_items, :text
      remove_index :tables, :name
      remove_index :users, :full_name
      remove_index :comments, :message
      remove_index :comments, :type
      remove_index :protocols, :protocol_type
      remove_index :checklists, :step_id

      execute('DROP FUNCTION IF EXISTS trim_html_tags(IN input TEXT);')
    end
  end
end
