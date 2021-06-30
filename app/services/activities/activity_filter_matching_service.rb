# frozen_string_literal: true

module Activities
  class ActivityFilterMatchingService
    def initialize(activity)
      @activity = activity
      @activity_filters = ActivityFilter.all
    end

    def activity_filters
      filter_date!
      filter_users!
      filter_types!
      filter_teams!
      filter_subjects!

      @activity_filters
    end

    private

    def filter_date!
      @activity_filters = @activity_filters.where(
        "((filter ->> 'from_date') = '' AND (filter ->> 'to_date') = '') OR " \
        "((?)::date BETWEEN (filter ->> 'from_date')::date AND (filter ->> 'to_date')::date)",
        @activity.created_at.to_date
      )
    end

    def filter_users!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'users') OR filter -> 'users' @> '\"#{@activity.owner_id}\"'"
      )
    end

    def filter_types!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'types') OR filter -> 'types' @> '\"#{@activity.type_of_before_type_cast}\"'"
      )
    end

    def filter_teams!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'teams') OR filter -> 'teams' @> '\"#{@activity.team_id}\"'"
      )
    end

    def filter_subjects!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'subjects') OR "\
        "filter -> 'subjects' -> '#{@activity.subject_type}' @> '\"#{@activity.subject_id}\"'"
      )
    end
  end
end
