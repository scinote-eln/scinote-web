# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    visible_teams = user.teams.where(id: teams)
    visible_projects = Project.viewable_by_user(user, visible_teams)
    query = Activity.where(project: visible_projects)
                    .or(Activity.where(project: nil, team: visible_teams))
    if filters[:subjects].present?
      subjects_with_children = load_subjects_children(filters[:subjects])
      if subjects_with_children[:Project]
        add_or = subjects_with_children.length > 1
        query = query.where("project_id IN (?) #{add_or ? 'OR' : ''}", subjects_with_children[:Project])
        subjects_with_children.except!(:Project)
      end
      query = query.where(
        subjects_with_children.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR '),
        *subjects_with_children.flatten
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
    subject_types = Extends::ACTIVITY_SUBJECT_CHILDREN
    subject_types.each do |subject_name, children|
      next unless children && subjects[subject_name]

      children.each do |child|
        parent_model = subject_name.to_s.constantize
        child_model = parent_model.reflect_on_association(child).class_name.to_sym
        child_id = parent_model.where(id: subjects[subject_name])
                               .joins(child)
                               .pluck("#{child}.id")
        subjects[child_model] = (subjects[child_model] ||= []) + child_id
      end
    end

    subjects.each { |_sub, children| children.uniq! }
  end
end
