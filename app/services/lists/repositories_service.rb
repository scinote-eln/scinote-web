# frozen_string_literal: true

module Lists
  class RepositoriesService < BaseService
    private

    def fetch_records
      @records = @raw_data.joins('LEFT OUTER JOIN users AS creators ' \
                                 'ON repositories.created_by_id = creators.id')
                          .joins('LEFT OUTER JOIN users AS archivers ' \
                                 'ON repositories.archived_by_id = archivers.id')
                          .joins(:team)
                          .select('repositories.*')
                          .select('MAX(teams.name) AS team_name')
                          .select('MAX(creators.full_name) AS created_by_user')
                          .select('MAX(archivers.full_name) AS archived_by_user')
                          .select(shared_sql_select)
                          .preload(:team_assignments, :user_group_assignments, user_assignments: %i(user user_role))
                          .group('repositories.id')

      view_mode = @params[:view_mode] || 'active'

      @records = @records.archived if view_mode == 'archived'
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        [
          'repositories.name',
          'teams.name',
          'creators.full_name',
          'archivers.full_name'
        ],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'repositories.name',
        team: 'team_name',
        created_by: 'created_by_user',
        created_at: 'repositories.created_at',
        archived_on: 'repositories.archived_on',
        archived_by: 'archived_by_user',
        nr_of_rows: 'repository_rows_count',
        code: 'repositories.id',
        shared_label: 'shared'
      }
    end

    def shared_sql_select
      shared_write_value = Repository.permission_levels['shared_write']
      not_shared_value = Repository.permission_levels['not_shared']
      team_id = @user.current_team.id

      case_statement = <<-SQL.squish
        CASE
          WHEN repositories.team_id = :team_id AND repositories.permission_level NOT IN (:not_shared_value)
            OR EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = repositories.id
              AND team_shared_objects.shared_object_type = 'RepositoryBase'
              AND team_shared_objects.team_id != :team_id
            ) THEN 1
          WHEN repositories.team_id != :team_id AND repositories.permission_level NOT IN (:not_shared_value)
            OR EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = repositories.id
              AND team_shared_objects.shared_object_type = 'RepositoryBase'
              AND team_shared_objects.team_id = :team_id
          ) THEN
              CASE
                WHEN repositories.permission_level IN (:shared_write_value)
                  OR EXISTS (
                    SELECT 1 FROM team_shared_objects
                    WHERE team_shared_objects.shared_object_id = repositories.id
                      AND team_shared_objects.shared_object_type = 'RepositoryBase'
                      AND team_shared_objects.permission_level = :shared_write_value
                      AND team_shared_objects.team_id = :team_id
                  ) THEN 2
                ELSE 3
              END
          ELSE 4
        END as shared
      SQL

      ActiveRecord::Base.sanitize_sql_array(
        [case_statement, { team_id:, not_shared_value:, shared_write_value: }]
      )
    end
  end
end
