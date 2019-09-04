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

    if filters[:query]
      # Search through localization file
      activities_translation = I18n.t('.')[:global_activities][:content].map do |k, v|
        k.to_s.split('_html')[0] if filters[:query].split(' ').any? { |word| v.include? word }
      end.compact
      search_translations_filter = Activity.type_ofs.map { |k, v| v if activities_translation.include? k }.compact

      # Search through object names
      message_items_counter = 1
      message_search = []
      message_joins = []

      Extends::ACTIVITY_MESSAGE_ITEMS.each do |message_item_group|
        message_item_group[:items].each do |message_item|
          message_joins.push("LEFT JOIN #{message_item_group[:table]} t#{message_items_counter} "\
            "ON t#{message_items_counter}.id = (activities.values -> 'message_items' -> '#{message_item}' ->> 'id')::INT")
          message_search.push("t#{message_items_counter}.#{message_item_group[:search_field]} ~* :query")
          message_items_counter += 1
        end
      end

      query = query\
              .joins(message_joins.join(' '))
              .where("
          (#{message_search.join(' OR ')}) AND type_of IN (:translations)
        ", query: filters[:query].split(' ').join('|'), translations: search_translations_filter)
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
