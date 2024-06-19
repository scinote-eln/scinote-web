# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    visible_teams = user.teams.where(id: teams)
    visible_projects = Project.viewable_by_user(user, visible_teams)
    visible_by_teams = Activity.where(project: nil, team_id: visible_teams.select(:id))
                               .order(created_at: :desc)
    visible_by_projects = Activity.where(project_id: visible_projects.select(:id))
                                  .order(created_at: :desc)

    query = Activity.from("((#{visible_by_teams.to_sql}) UNION ALL (#{visible_by_projects.to_sql})) AS activities")

    if filters[:subjects].present?
      subjects_with_children = load_subjects_children(filters[:subjects])
      where_condition = subjects_with_children.to_h.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR ')
      where_arguments = subjects_with_children.to_h.flatten
      if subjects_with_children[:my_module]
        where_condition = where_condition.concat(' OR (my_module_id IN(?))')
        where_arguments << subjects_with_children[:my_module]
      end
      query = query.where(where_condition, *where_arguments)
    end

    query = query.where(owner_id: filters[:users]) if filters[:users]
    query = query.where(type_of: filters[:types].map(&:to_i)) if filters[:types]

    activities =
      if filters[:from_date].present? && filters[:to_date].present?
        query.where('created_at <= :from AND created_at >= :to',
                    from: Time.zone.parse(filters[:from_date]).end_of_day.utc,
                    to: Time.zone.parse(filters[:to_date]).beginning_of_day.utc)
      elsif filters[:from_date].present? && filters[:to_date].blank?
        query.where('created_at <= :from', from: Time.zone.parse(filters[:from_date]).end_of_day.utc)
      elsif filters[:from_date].blank? && filters[:to_date].present?
        query.where('created_at >= :to', to: Time.zone.parse(filters[:to_date]).beginning_of_day.utc)
      else
        query
      end

    activities.order(created_at: :desc)
              .page(filters[:page])
              .per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
              .without_count
  end

  def self.load_subjects_children(subjects = {})
    Extends::ACTIVITY_SUBJECT_CHILDREN.each do |subject_name, children|
      subject_name = subject_name.to_s.camelize
      next unless children && subjects[subject_name]

      children.each do |child|
        parent_model = subject_name.constantize
        child_model = parent_model.reflect_on_association(child).class_name.to_sym
        next if subjects[child_model]

        subjects[child_model] = parent_model.where(id: subjects[subject_name])
                                            .joins(child)
                                            .pluck("#{child.to_s.pluralize}.id")
      end
    end

    subjects.each { |_sub, children| children.uniq! }
  end

  def self.my_module_activities(my_module)
    subjects_with_children = load_subjects_children('MyModule' => [my_module.id])
    query = Activity.where(project: my_module.experiment.project)
    query.where(
      subjects_with_children.to_h.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR '),
      *subjects_with_children.to_h.flatten
    )
  end

  def self.activity_matches_filter?(user, teams, activity, activity_filter)
    load_activities(user, teams, activity_filter.filter).where(id: activity.id).any?
  end
end
