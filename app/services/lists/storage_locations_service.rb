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
                              'ON storage_locations.id = sub_locations.parent_id AND sub_locations.discarded_at IS NULL')
                       .left_joins(:team, :created_by)
                       .select(StorageLocation.shared_sql_select(@user))
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

      if @filters[:query].present?
        @records = @records.where_attributes_like(
          [
            'storage_locations.name',
            'storage_locations.description',
            StorageLocation::PREFIXED_ID_SQL
          ], @filters[:query]
        )
      end

      if @params[:search].present?
        @records = @records.where_attributes_like(
          [
            'storage_locations.name',
            'storage_locations.description',
            StorageLocation::PREFIXED_ID_SQL
          ], @params[:search]
        )
      end
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
      when 'name_hash_ASC'
        @records = @records.order(name: :asc)
      when 'name_hash_DESC'
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
  end
end
