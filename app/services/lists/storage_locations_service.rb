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
  end
end
