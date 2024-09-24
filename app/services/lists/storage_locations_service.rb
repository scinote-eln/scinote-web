# frozen_string_literal: true

module Lists
  class StorageLocationsService < BaseService
    include Canaid::Helpers::PermissionsHelper

    def initialize(user, team, params)
      @user = user
      @team = team
      @parent_id = params[:parent_id]
      @filters = params[:filters] || {}
      @params = params
    end

    def fetch_records
      if @parent_id && !can_read_storage_location?(@user, StorageLocation.find(@parent_id))
        @records = StorageLocation.none
        return
      end

      @records =
        StorageLocation.joins('LEFT JOIN storage_locations AS sub_locations ' \
                              'ON storage_locations.id = sub_locations.parent_id')
                       .left_joins(:team, :created_by)
                       .select(shared_sql_select)
                       .select(
                         'storage_locations.*,
                        MAX(teams.name) as team_name,
                        MAX(users.full_name) as created_by_full_name,
                        CASE WHEN storage_locations.container THEN -1 ELSE COUNT(sub_locations.id) END AS sub_location_count'
                       )
                       .group(:id)

      @records = @records.viewable_by_user(@user, @team) unless @parent_id
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

      @records = @records.where('LOWER(storage_locations.name) ILIKE ?', "%#{@filters[:query].downcase}%") if @filters[:query].present?
      @records = @records.where('LOWER(storage_locations.name) ILIKE ?', "%#{@params[:search].downcase}%") if @params[:search].present?
    end

    private

    def sort_records
      return unless @params[:order]

      sort = "#{order_params[:column]}_#{sort_direction(order_params)}"

      case sort
      when 'code_ASC'
        @records = @records.order(id: :asc)
      when 'code_DESC'
        @records = @records.order(id: :desc)
      when 'name_ASC'
        @records = @records.order(name: :asc)
      when 'name_DESC'
        @records = @records.order(name: :desc)
      when 'sub_location_count_ASC'
        @records = @records.order(sub_location_count: :asc)
      when 'sub_location_count_DESC'
        @records = @records.order(sub_location_count: :desc)
      when 'owned_by_ASC'
        @records = @records.order('team_name ASC')
      when 'owned_by_DESC'
        @records = @records.order('team_name DESC')
      when 'shared_label_ASC'
        @records = @records.order('shared ASC')
      when 'shared_label_DESC'
        @records = @records.order('shared DESC')
      when 'created_on_ASC'
        @records = @records.order(created_at: :asc)
      when 'created_on_DESC'
        @records = @records.order(created_at: :desc)
      when 'created_by_ASC'
        @records = @records.order('created_by_full_name ASC')
      when 'created_by_DESC'
        @records = @records.order('created_by_full_name DESC')
      end
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
              AND storage_locations.team_id = :team_id
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
        [case_statement, { team_id: team_id, shared_write_value: shared_write_value }]
      )
    end
  end
end
