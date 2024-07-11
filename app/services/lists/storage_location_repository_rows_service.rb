# frozen_string_literal: true

module Lists
  class StorageLocationRepositoryRowsService < BaseService
    def initialize(team, params)
      @team = team
      @storage_location_id = params[:storage_location_id]
      @params = params
    end

    def fetch_records
      @records = StorageLocationRepositoryRow.includes(:repository_row).where(storage_location_id: @storage_location_id)
    end

    def filter_records; end
  end
end
