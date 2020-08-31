require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddSearchQueryIndexes < ActiveRecord::Migration[4.2]
  def up
    add_index :projects, :team_id
    add_index :user_teams, :user_id
    add_index :user_teams, :team_id
    add_index :user_projects, :user_id
    add_index :user_projects, :project_id
    add_index :tags, :project_id

    # Add GIST trigram indexes onto columns that check for
    # ILIKE %pattern% during search
    if db_adapter_is? "PostgreSQL" then
      add_gist_index :projects, :name
      add_gist_index :my_modules, :name
      add_gist_index :my_module_groups, :name
      add_gist_index :tags, :name
      add_gist_index :steps, :name
      add_gist_index :results, :name

      # There's already semi-useless BTree index on samples
      remove_index :samples, :name
      add_gist_index :samples, :name
    end
  end

  def down
    remove_index :projects, :team_id
    remove_index :user_teams, :user_id
    remove_index :user_teams, :team_id
    remove_index :user_projects, :user_id
    remove_index :user_projects, :project_id
    remove_index :tags, :project_id

    if db_adapter_is? "PostgreSQL" then
      remove_index :projects, :name
      remove_index :my_modules, :name
      remove_index :my_module_groups, :name
      remove_index :tags, :name
      remove_index :steps, :name
      remove_index :results, :name

      # Re-add semi-useless BTree index on samples
      remove_index :samples, :name
      add_index :samples, :name
    end
  end
end
