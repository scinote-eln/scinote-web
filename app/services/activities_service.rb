# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    visible_teams = user.teams.where(id: teams)
    visible_projects = Project.viewable_by_user(user, visible_teams)
    visible_by_teams = Activity.where(project: nil, team_id: visible_teams.pluck(:id))
                               .order(created_at: :desc)
    visible_by_projects = Activity.where(project_id: visible_projects.pluck(:id))
                                  .order(created_at: :desc)

    query = Activity.from("((#{visible_by_teams.to_sql}) UNION ALL (#{visible_by_projects.to_sql})) AS activities")

    if filters[:subjects].present?
      subjects_with_children = load_subjects_children(filters[:subjects])
      if subjects_with_children[:project]
        query = query.where('project_id IN (?)', subjects_with_children[:project])
        subjects_with_children.except!(:project)
      end
      where_condition = subjects_with_children.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR ')
      where_arguments = subjects_with_children.flatten
      if subjects_with_children[:my_module]
        where_condition = where_condition.concat(' OR (my_module_id IN(?))')
        where_arguments << subjects_with_children[:my_module]
      end
      query = query.where(where_condition, *where_arguments)
    end

    query = query.where(owner_id: filters[:users]) if filters[:users]
    query = query.where(type_of: filters[:types]) if filters[:types]
    query = query.where('created_at <= ?', Time.at(filters[:starting_timestamp].to_i)) if filters[:starting_timestamp]

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

    activities.order(created_at: :desc)
              .page(filters[:page])
              .per(Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
              .without_count
  end

  def self.load_subjects_children(subjects = {})
    Extends::ACTIVITY_SUBJECT_CHILDREN.each do |subject_name, children|
      next unless children && subjects[subject_name]

      children.each do |child|
        parent_model = subject_name.to_s.camelize.constantize
        child_model = parent_model.reflect_on_association(child).class_name.to_sym
        next if subjects[child_model]

        subjects[child_model] = parent_model.where(id: subjects[subject_name])
                                            .joins(child)
                                            .pluck("#{child}.id")
      end
    end

    subjects.each { |_sub, children| children.uniq! }
  end

  def self.my_module_activities(my_module)
    subjects_with_children = load_subjects_children(my_module: [my_module.id])
    query = Activity.where(project: my_module.experiment.project)
    query.where(
      subjects_with_children.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR '),
      *subjects_with_children.flatten
    )
  end
end
