# frozen_string_literal: true

module Lists
  class FormsService < BaseService
    def initialize(user, team, params)
      super(nil, params, user: user)
      @team = team
    end

    def fetch_records
      @records =
        Form.includes(:team, user_assignments: %i(user user_role))
            .left_outer_joins(:user_assignments)
            .left_outer_joins(:form_responses)
            .viewable_by_user(@user, @team)
            .joins(
              'LEFT OUTER JOIN users AS publishers ' \
              'ON forms.published_by_id = publishers.id'
            ).select(
              'forms.* AS forms',
              'publishers.full_name AS published_by_user',
              'COUNT(DISTINCT form_responses.id) AS used_in_protocols_count',
              'COUNT(DISTINCT user_assignments.id) AS user_assignment_count'
            ).where(team: @team).group('forms.id', 'publishers.full_name')

      view_mode = @params[:view_mode] || 'active'

      @records = @records.archived if view_mode == 'archived'
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      return unless @params[:search]

      @records = @records.where_attributes_like(
        ['forms.name'],
        @params[:search]
      )
    end

    def sort_records
      return unless @params[:order]

      super
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'forms.name',
        id: 'forms.id',
        updated_at: 'forms.updated_at',
        assigned_users: 'user_assignment_count',
        used_in_protocols: 'used_in_protocols_count',
        versions: 'forms.published_on', # temporary until proper versioning is implemented
        published_by: 'published_by_user',
        published_on: 'forms.published_on'
      }
    end
  end
end
