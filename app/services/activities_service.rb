# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    visible_teams = user.teams.where(id: teams)
    visible_projects = Project.viewable_by_user(user, visible_teams)
    query = Activity.where(project: visible_projects)
                    .or(Activity.where(project: nil, team: visible_teams))
    if filters[:subjects].present?
      subjects_with_childrens = load_subjects_children(filters[:subjects])
      query = query.where(
        subjects_with_childrens.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR '),
        *subjects_with_childrens.flatten
      )
    end

    query = query.where(owner_id: filters[:users]) if filters[:users]
    query = query.where(type_of: filters[:types]) if filters[:types]

    activities =
      if filters[:from_date].present? && filters[:to_date].present?
        query.where('created_at <= :from AND created_at >= :to',
                    from: Time.zone.parse(filters[:from_date]).end_of_day.utc,
                    to: Time.zone.parse(filters[:to_date]).beginning_of_day.utc)
      elsif filters[:from_date].present? && filters[:to_date].blank?
        query.where('created_at <= :from', from: Time.zone.parse(filters[:from_date]).end_of_day.utc)
      else
        query
      end

    activities = activities.order(created_at: :desc)
                           .limit(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    loaded = activities.length
    results = activities.group_by do |activity|
      Time.zone.at(activity.created_at).to_date.to_s
    end

    return results if loaded < Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT

    last_date = results.keys.last
    activities = query.where(
      'created_at <= :from AND created_at >= :to',
      from: Time.zone.parse(last_date).end_of_day.utc,
      to: Time.zone.parse(last_date).beginning_of_day.utc
    ).order(created_at: :desc)

    more_left = query.where(
      'created_at < :from',
      from: Time.zone.parse(last_date).prev_day.end_of_day.utc
    ).exists?

    results[last_date] = activities.to_a
    [results, more_left]
  end

  def self.load_subjects_children(subjects = {})
    subject_types = Extends::ACTIVITY_SUBJECT_CHILDRENS
    subject_types.each do |subject_name, childrens|
      next unless childrens && subjects[subject_name]

      childrens.each do |children|
        parent_model = subject_name.to_s.constantize
        child_model = parent_model.reflect_on_association(children).class_name.to_sym
        childrens_id = parent_model.where(id: subjects[subject_name])
                                   .joins(children)
                                   .pluck("#{children}.id")
        subjects[child_model] = (subjects[child_model] ||= []) + childrens_id
      end
    end

    subjects.each { |_sub, childs| childs.uniq! }
  end
end
