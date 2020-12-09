require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class UpdateIndexesForFasterSearch < ActiveRecord::Migration[4.2]
  def up
    if db_adapter_is? 'PostgreSQL'
      # Removing old indexes
      if index_name_exists? :projects, :index_projects_on_name
        remove_index :projects, name: :index_projects_on_name
      end
      if index_name_exists? :my_modules, :index_my_modules_on_name
        remove_index :my_modules, name: :index_my_modules_on_name
      end
      if index_name_exists? :my_modules, :index_my_modules_on_description
        remove_index :my_modules, name: :index_my_modules_on_description
      end
      if index_name_exists? :protocols, :index_protocols_on_name
        remove_index :protocols, name: :index_protocols_on_name
      end
      if index_name_exists? :protocols, :index_protocols_on_description
        remove_index :protocols, name: :index_protocols_on_description
      end
      if index_name_exists? :protocols, :index_protocols_on_authors
        remove_index :protocols, name: :index_protocols_on_authors
      end
      if index_name_exists? :protocol_keywords, :index_protocol_keywords_on_name
        remove_index :protocol_keywords, name: :index_protocol_keywords_on_name
      end
      if index_name_exists? :my_module_groups, :index_my_module_groups_on_name
        remove_index :my_module_groups, name: :index_my_module_groups_on_name
      end
      if index_name_exists? :tags, :index_tags_on_name
        remove_index :tags, name: :index_tags_on_name
      end
      if index_name_exists? :results, :index_results_on_name
        remove_index :results, name: :index_results_on_name
      end
      if index_name_exists? :result_texts, :index_result_texts_on_text
        remove_index :result_texts, name: :index_result_texts_on_text
      end
      if index_name_exists? :reports, :index_reports_on_name
        remove_index :reports, name: :index_reports_on_name
      end
      if index_name_exists? :reports, :index_reports_on_description
        remove_index :reports, name: :index_reports_on_description
      end
      if index_name_exists? :samples, :index_samples_on_name
        remove_index :samples, name: :index_samples_on_name
      end
      if index_name_exists? :sample_types, :index_sample_types_on_name
        remove_index :sample_types, name: :index_sample_types_on_name
      end
      if index_name_exists? :sample_groups, :index_sample_groups_on_name
        remove_index :sample_groups, name: :index_sample_groups_on_name
      end
      if index_name_exists? :sample_custom_fields,
                            :index_sample_custom_fields_on_value
        remove_index :sample_custom_fields,
                     name: :index_sample_custom_fields_on_value
      end
      if index_name_exists? :steps, :index_steps_on_name
        remove_index :steps, name: :index_steps_on_name
      end
      if index_name_exists? :steps, :index_steps_on_description
        remove_index :steps, name: :index_steps_on_description
      end
      if index_name_exists? :checklists, :index_checklists_on_name
        remove_index :checklists, name: :index_checklists_on_name
      end
      if index_name_exists? :checklist_items, :index_checklist_items_on_text
        remove_index :checklist_items, name: :index_checklist_items_on_text
      end
      if index_name_exists? :tables, :index_tables_on_name
        remove_index :tables, name: :index_tables_on_name
      end
      if index_name_exists? :users, :index_users_on_full_name
        remove_index :users, name: :index_users_on_full_name
      end
      if index_name_exists? :comments, :index_comments_on_message
        remove_index :comments, name: :index_comments_on_message
      end
      if index_name_exists? :comments, :index_comments_on_type
        remove_index :comments, name: :index_comments_on_type
      end
      if index_name_exists? :protocols, :index_protocols_on_protocol_type
        remove_index :protocols, name: :index_protocols_on_protocol_type
      end
      if index_name_exists? :checklists, :index_checklists_on_step_id
        remove_index :checklists, name: :index_checklists_on_step_id
      end

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
