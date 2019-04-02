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
        query = query.where('project_id IN (?)', subjects_with_children[:Project])
        subjects_with_children.except!(:Project)
      end
      where_condition = subjects_with_children.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR ')
      where_arguments = subjects_with_children.flatten
      if subjects_with_children[:MyModule]
        where_condition = where_condition.concat(' OR (my_module_id IN(?))')
        where_arguments << subjects_with_children[:MyModule]
      end
      query = query.where(where_condition, *where_arguments)
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

  def self.my_module_activities(my_module)
    subjects_with_children = load_subjects_children(MyModule: [my_module.id])
    query = Activity.where(project: my_module.experiment.project)
    query.where(
      subjects_with_children.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR '),
      *subjects_with_children.flatten
    )
  end
end
