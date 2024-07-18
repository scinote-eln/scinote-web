# frozen_string_literal: true

module Lists
  class StorageLocationsService < BaseService
    def initialize(team, params)
      @team = team
      @parent_id = params[:parent_id]
      @params = params
    end

    def fetch_records
      @records =
        StorageLocation.joins('LEFT JOIN storage_locations AS sub_locations ' \
                              'ON storage_locations.id = sub_locations.parent_id')
                       .select('storage_locations.*, COUNT(sub_locations.id) AS sub_location_count')
                       .where(team: @team, parent_id: @parent_id)
                       .group(:id)
    end

    def filter_records; end
  end
end
