# frozen_string_literal: true

module Lists
  class StorageLocationsService < BaseService
    def initialize(team, params)
      @team = team
      @parent_id = params[:parent_id]
      @params = params
    end

    def fetch_records
      @records = @team.storage_locations.where(parent_id: @parent_id)
    end

    def filter_records; end
  end
end
