# frozen_string_literal: true

module Activities
  class ActivityFilterMatchingService
    # invert the children hash to get a hash defining parents
    ACTIVITY_SUBJECT_PARENTS = Extends::ACTIVITY_SUBJECT_CHILDREN.invert.map do |k, v|
      k&.map { |s| [s.to_s.classify, v.to_s.classify.constantize.reflect_on_association(s)&.inverse_of&.name || v] }
    end.compact.sum.to_h.freeze

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
      @activity_filters =@activity_filters.where(
        "(CASE "\
        "WHEN (filter ->> 'to_date') = '' " \
        "THEN :date >= '-infinity'::date " \
        "ELSE :date >= (filter ->> 'to_date')::date " \
        "END) " \
        " AND " \
        "(CASE "\
        "WHEN (filter ->> 'from_date') = '' " \
        "THEN :date <= 'infinity'::date " \
        "ELSE :date <=  (filter ->> 'from_date')::date "\
        "END)",
        date: @activity.created_at.to_date
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
      parents = activity_subject_parents

      @activity_filters = @activity_filters.where(
        "NOT(filter ? 'subjects') OR "\
        "filter -> 'subjects' -> 'Project' @> '\"#{@activity.project_id}\"' OR "\
        "filter -> 'subjects' -> '#{@activity.subject_type}' @> '\"#{@activity.subject_id}\"'" +
          (parents.any? ? ' OR ' : '') +
          parents.map do |subject|
            "filter -> 'subjects' -> '#{subject.class}' @> '\"#{subject.id}\"'"
          end.join(' OR ')
      )
    end

    def activity_subject_parents
      subject_parents(@activity.subject, []).compact
    end

    def subject_parents(subject, parents)
      parent_model_name = ACTIVITY_SUBJECT_PARENTS[subject.class.name]
      return parents if parent_model_name.nil?

      parent = subject.public_send(parent_model_name)
      subject_parents(parent, parents << parent)
    end
  end
end
