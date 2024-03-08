# frozen_string_literal: true

module Lists
  class RepositoriesService < BaseService
    private

    def fetch_records
      @records = @raw_data.joins('LEFT OUTER JOIN users AS creators ' \
                                 'ON repositories.created_by_id = creators.id')
                          .joins('LEFT OUTER JOIN users AS archivers ' \
                                 'ON repositories.archived_by_id = archivers.id')
                          .left_outer_joins(:repository_rows)
                          .joins(:team)
                          .select('repositories.*')
                          .select('MAX(teams.name) AS team_name')
                          .select('COUNT(repository_rows.*) AS row_count')
                          .select('MAX(creators.full_name) AS created_by_user')
                          .select('MAX(archivers.full_name) AS archived_by_user')
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
        nr_of_rows: 'row_count',
        code: 'repositories.id'
      }
    end
  end
end
