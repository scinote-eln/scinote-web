# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    visible_teams = user.teams.where(id: teams)
    visible_projects = Project.viewable_by_user(user, visible_teams)
    visible_my_modules = MyModule.joins(:experiment)
                                 .where(experiments: { project_id: visible_projects.select(:id) })
                                 .viewable_by_user(user, teams)

    # Temporary solution until handling of deleted subjects is fully implemented
    visible_repository_teams = visible_teams.with_user_permission(user, RepositoryPermissions::READ)
    visible_by_teams = Activity.where(project: nil, team_id: visible_teams.select(:id))
                               .where.not(subject_type: %w(RepositoryBase RepositoryRow Protocol))
                               .order(created_at: :desc)
    visible_by_repositories = Activity.where(subject_type: %w(RepositoryBase RepositoryRow), team_id: visible_repository_teams.select(:id))
                                      .order(created_at: :desc)
    visible_by_projects = Activity.where(project_id: visible_projects.select(:id))
                                  .where.not(subject_type: %w(MyModule Result Protocol))
                                  .order(created_at: :desc)

    visible_by_my_modules = Activity.where("subject_id IN (?) AND subject_type = 'MyModule' OR " \
                                           "subject_id IN (?) AND subject_type = 'Result' OR " \
                                           "subject_id IN (?) AND subject_type = 'Protocol'",
                                           visible_my_modules.select(:id),
                                           Result.where(my_module: visible_my_modules).select(:id),
                                           Protocol.where(my_module: visible_my_modules).select(:id))
                                    .order(created_at: :asc)

    visible_by_protocol_templates =
      Activity.where(
        subject_type: Protocol,
        subject_id: Protocol.where(team_id: visible_teams.select(:id)).viewable_by_user(user, teams)
      ).order(created_at: :desc)

    query = Activity.from(
      "((#{visible_by_teams.to_sql}) UNION ALL " \
      "(#{visible_by_repositories.to_sql}) UNION ALL " \
      "(#{visible_by_protocol_templates.to_sql}) UNION ALL " \
      "(#{visible_by_my_modules.to_sql}) UNION ALL " \
      "(#{visible_by_projects.to_sql})) AS activities"
    )

    if filters[:subjects].present?
      subjects_with_children = load_subjects_children(filters[:subjects], user, teams)
      where_condition = subjects_with_children.to_h.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR ')
      where_arguments = subjects_with_children.to_h.flatten
      if subjects_with_children[:my_module]
        where_condition.concat(' OR (my_module_id IN(?))')
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

  def self.load_subjects_children(subjects = {}, user = nil, teams = nil)
    Extends::ACTIVITY_SUBJECT_CHILDREN.each do |subject_name, children|
      subject_name = subject_name.to_s.camelize
      next unless children && subjects[subject_name]

      children.each do |child|
        parent_model = subject_name.constantize
        child_model = parent_model.reflect_on_association(child).class_name.to_sym
        next if subjects[child_model]

        parent_model = parent_model.with_discarded if subject_name == 'Result'

        subjects[child_model] =
          case child
          when :results
            parent_model.where(id: subjects[subject_name])
                        .joins(:results_include_discarded)
                        .pluck('results.id')
          when :repositories
            parent_model.viewable_by_user(user, teams)
                        .where(id: subjects[subject_name])
                        .pluck('repositories.id')
          else
            parent_model.where(id: subjects[subject_name])
                        .joins(child)
                        .pluck("#{child.to_s.pluralize}.id")
          end
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
