# frozen_string_literal: true

class ActivitiesService
  def self.load_activities(user, teams, filters = {})
    # Create condition for view permissions checking first
    teams = user.teams.where(id: teams).pluck(:id)
    activities = Activity.where(team: teams)

    if filters[:subjects].present?
      subjects_with_children = load_subjects_children(filters[:subjects], user, teams)
      where_condition = subjects_with_children.to_h.map { '(subject_type = ? AND subject_id IN(?))' }.join(' OR ')
      where_arguments = subjects_with_children.to_h.flatten
      if subjects_with_children[:my_module]
        where_condition.concat(' OR (my_module_id IN(?))')
        where_arguments << subjects_with_children[:my_module]
      end
      activities = activities.where(where_condition, *where_arguments)
    end

    activities = activities.where(owner_id: filters[:users]) if filters[:users]
    activities = activities.where(type_of: filters[:types].map(&:to_i)) if filters[:types]

    activities =
      if filters[:from_date].present? && filters[:to_date].present?
        activities.where('activities.created_at <= :from AND activities.created_at >= :to',
                         from: Time.zone.parse(filters[:from_date]).end_of_day.utc,
                         to: Time.zone.parse(filters[:to_date]).beginning_of_day.utc)
      elsif filters[:from_date].present? && filters[:to_date].blank?
        activities.where('activities.created_at <= :from', from: Time.zone.parse(filters[:from_date]).end_of_day.utc)
      elsif filters[:from_date].blank? && filters[:to_date].present?
        activities.where('activities.created_at' => Time.zone.parse(filters[:to_date]).beginning_of_day.utc..)
      else
        activities
      end

    visible_projects = Project.readable_by_user(user, teams)
    visible_my_modules = MyModule.readable_by_user(user, teams)
    visible_forms = Form.readable_by_user(user, teams)
    visible_repositories = Repository.readable_by_user(user, teams)
    visible_protocol_templates = Protocol.readable_by_user(user, teams)
    visible_results = Result.with_discarded.where(my_module: visible_my_modules)
    visible_result_templates = ResultTemplate.with_discarded.where(protocol: visible_protocol_templates)

    deleted_repository_activities =
      activities.where(subject_type: %w(RepositoryBase RepositoryRow))
                .joins("LEFT OUTER JOIN repositories ON (activities.subject_id = repositories.id AND activities.subject_type = 'RepositoryBase')")
                .joins("LEFT OUTER JOIN repository_rows ON (activities.subject_id = repository_rows.id AND activities.subject_type = 'RepositoryRow')")
                .where("(activities.subject_type = 'RepositoryBase' AND repositories.id IS NULL) OR
                        (activities.subject_type = 'RepositoryRow' AND repository_rows.id IS NULL)")

    activities = Activity.from(activities, 'activities')
    activities = activities.where(project: nil, team_id: teams).where.not(subject_type: %w(RepositoryBase RepositoryRow Protocol ResultBase Form))
                           .or(activities.where(id: deleted_repository_activities.select(:id)))
                           .or(activities.where(subject_type: 'Protocol', subject_id: visible_protocol_templates.select(:id)))
                           .or(activities.where(project_id: visible_projects.select(:id)).where.not(subject_type: %w(Experiment MyModule ResultBase Result Protocol)))
                           .or(activities.where(subject_type: 'Experiment', subject_id: Experiment.readable_by_user(user, teams).select(:id)))
                           .or(activities.where("subject_id IN (?) AND subject_type = 'MyModule' OR " \
                                                "subject_id IN (?) AND subject_type = 'ResultBase' OR " \
                                                "subject_id IN (?) AND subject_type = 'Protocol' OR " \
                                                "subject_id IN (?) AND subject_type = 'Form' OR " \
                                                "subject_id IN (?) AND subject_type = 'RepositoryBase' OR " \
                                                "subject_id IN (?) AND subject_type = 'RepositoryRow'",
                                                visible_my_modules.select(:id),
                                                ResultBase.with_discarded.where(id: visible_results).or(ResultBase.with_discarded.where(id: visible_result_templates)).select(:id),
                                                Protocol.where(my_module: visible_my_modules).select(:id),
                                                visible_forms.select(:id),
                                                visible_repositories.select(:id),
                                                RepositoryRow.where(repository_id: visible_repositories).select(:id)))

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
            parent_model.readable_by_user(user, teams)
                        .where(id: subjects[subject_name])
                        .pluck('repositories.id')
          else
            parent_model.where(id: subjects[subject_name])
                        .joins(child)
                        .pluck("#{child.to_s.pluralize}.id")
          end
      end
    end

    # also handles special case for Result and ResultBase STI
    subjects.to_h do |subject, children|
      [subject == 'Result' ? 'ResultBase' : subject, children.uniq]
    end
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
