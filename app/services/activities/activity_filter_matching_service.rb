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
        "(CASE " \
        "WHEN ((filter ->> 'to_date') = '') IS NOT FALSE " \
        "THEN :date >= '-infinity'::date " \
        "ELSE :date >= (filter ->> 'to_date')::date " \
        "END) " \
        "AND " \
        "(CASE " \
        "WHEN ((filter ->> 'from_date') = '') IS NOT FALSE " \
        "THEN :date <= 'infinity'::date " \
        "ELSE :date <=  (filter ->> 'from_date')::date " \
        "END)",
        date: @activity.created_at.to_date
      )
    end

    def filter_users!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'users') OR filter -> 'users' @> '\":owner_id\"'", owner_id: @activity.owner_id
      )
    end

    def filter_types!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'types') OR filter -> 'types' @> '\":type_of\"'", type_of: @activity.type_of_before_type_cast
      )
    end

    def filter_teams!
      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'teams') OR filter -> 'teams' @> '\":team_id\"'", team_id: @activity.team_id
      )
    end

    def filter_subjects!
      parents = @activity.subject_parents
      filtered_by_subject = @activity_filters

      filtered_by_subject =
        @activity_filters
        .where("NOT(filter ? 'subjects')")
        .or(@activity_filters.where("filter -> 'subjects' -> 'Project' @> '\":subject_id\"'",
                                    subject_id: @activity.project_id))
        .or(@activity_filters.where("filter -> 'subjects' -> :subject_type @> '\":subject_id\"'",
                                    subject_type: @activity.subject_type, subject_id: @activity.subject_id))
      parents.each do |parent|
        filtered_by_subject =
          filtered_by_subject
          .or(@activity_filters.where("filter -> 'subjects' -> :subject_type @> '\":subject_id\"'",
                                      subject_type: parent.class, subject_id: parent.id))
      end
      @activity_filters = filtered_by_subject
    end
  end
end
