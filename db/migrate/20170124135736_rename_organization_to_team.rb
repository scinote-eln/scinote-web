class RenameOrganizationToTeam < ActiveRecord::Migration[4.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?('organizations') &&
           ActiveRecord::Base.connection.table_exists?('user_organizations')
      return
    end
    rename_table :organizations, :teams
    rename_table :user_organizations, :user_teams

    rename_column :custom_fields, :organization_id, :team_id
    rename_column :logs, :organization_id, :team_id
    rename_column :projects, :organization_id, :team_id
    rename_column :protocol_keywords, :organization_id, :team_id
    rename_column :protocols, :organization_id, :team_id
    rename_column :sample_groups, :organization_id, :team_id
    rename_column :sample_types, :organization_id, :team_id
    rename_column :samples, :organization_id, :team_id
    rename_column :samples_tables, :organization_id, :team_id
    rename_column :user_teams, :organization_id, :team_id
    rename_column :users, :current_organization_id, :current_team_id
  end

  def down
    unless ActiveRecord::Base.connection.table_exists?('teams') &&
           ActiveRecord::Base.connection.table_exists?('user_teams')
      return
    end
    rename_table :teams, :organizations
    rename_table  :user_teams, :user_organizations

    rename_column :custom_fields, :team_id, :organization_id
    rename_column :logs, :team_id, :organization_id
    rename_column :projects, :team_id, :organization_id
    rename_column :protocol_keywords, :team_id, :organization_id
    rename_column :protocols, :team_id, :organization_id
    rename_column :sample_groups, :team_id, :organization_id
    rename_column :sample_types, :team_id, :organization_id
    rename_column :samples, :team_id, :organization_id
    rename_column :samples_tables, :team_id, :organization_id
    rename_column :user_organizations, :team_id, :organization_id
    rename_column :users, :current_team_id, :current_organization_id
  end
end
