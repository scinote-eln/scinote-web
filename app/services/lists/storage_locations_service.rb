# frozen_string_literal: true

module Lists
  class StorageLocationsService < BaseService
    def initialize(user, team, params)
      @user = user
      @team = team
      @parent_id = params[:parent_id]
      @filters = params[:filters] || {}
      @params = params
    end

    def fetch_records
      @records =
        StorageLocation.joins('LEFT JOIN storage_locations AS sub_locations ' \
                              'ON storage_locations.id = sub_locations.parent_id')
                       .viewable_by_user(@user, @team)
                       .select(shared_sql_select)
                       .select('storage_locations.*, COUNT(sub_locations.id) AS sub_location_count')
                       .group(:id)
    end

    def filter_records
      if @filters[:search_tree].present?
        if @parent_id.present?
          storage_location = @records.find_by(id: @parent_id)
          @records = @records.where(id: StorageLocation.inner_storage_locations(@team, storage_location))
        end
      else
        @records = @records.where(parent_id: @parent_id)
      end

      @records = @records.where('LOWER(name) ILIKE ?', "%#{@filters[:query].downcase}%") if @filters[:query].present?
      @records = @records.where('LOWER(name) ILIKE ?', "%#{@params[:search].downcase}%") if @params[:search].present?
    end

    private

    def sort_records
      return
    end

    def shared_sql_select
      shared_write_value = TeamSharedObject.permission_levels['shared_write']
      team_id = @user.current_team.id

      case_statement = <<-SQL.squish
        CASE
          WHEN EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = storage_locations.id
              AND team_shared_objects.shared_object_type = 'StorageLocation'
            ) THEN 1
          WHEN EXISTS (
            SELECT 1 FROM team_shared_objects
            WHERE team_shared_objects.shared_object_id = storage_locations.id
              AND team_shared_objects.shared_object_type = 'StorageLocation'
              AND team_shared_objects.team_id = :team_id
          ) THEN
              CASE
                WHEN EXISTS (
                    SELECT 1 FROM team_shared_objects
                    WHERE team_shared_objects.shared_object_id = storage_locations.id
                      AND team_shared_objects.shared_object_type = 'StorageLocation'
                      AND team_shared_objects.permission_level = :shared_write_value
                      AND team_shared_objects.team_id = :team_id
                  ) THEN 2
                ELSE 3
              END
          ELSE 4
        END as shared
      SQL

      ActiveRecord::Base.sanitize_sql_array(
        [case_statement, { team_id: team_id , shared_write_value: shared_write_value }]
      )
    end
  end
end
