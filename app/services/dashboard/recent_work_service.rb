# frozen_string_literal: true

module Dashboard
  class RecentWorkService
    include PermissionExtends
    include InputSanitizeHelper
    include Rails.application.routes.url_helpers

    def initialize(user, team, mode)
      @user = user
      @team = team
      @mode = mode
    end

    def call
      all_activities = @team.activities.where(owner_id: @user.id)
      all_activities = join_project_user_roles(all_activities)
      all_activities = join_report_project_user_roles(all_activities)
      all_activities = join_experiment_user_roles(all_activities)
      all_activities = join_my_module_user_roles(all_activities)
      all_activities = join_result_user_roles(all_activities)
      all_activities = join_protocol_user_roles(all_activities)
      all_activities = join_step_user_roles(all_activities)

      team_activities = all_activities.where(subject_type: %w(Team RepositoryBase ProjectFolder))
      project_activities = all_activities.where.not(project_user_roles: { id: nil })
      report_activities = all_activities.where.not(report_project_user_roles: { id: nil })
      experiment_activities = all_activities.where.not(experiment_user_roles: { id: nil })
      my_module_activities = all_activities.where.not(my_module_user_roles: { id: nil })
      result_activities = all_activities.where.not(result_my_module_user_roles: { id: nil })
      protocol_activities = all_activities.where.not(protocol_my_module_user_roles: { id: nil })
      protocol_repository_activities = all_activities.where(project_id: nil, subject_type: 'Protocol')
      step_activities = all_activities.where.not(step_my_module_user_roles: { id: nil })

      activities = team_activities.or(project_activities)
                                  .or(report_activities)
                                  .or(experiment_activities)
                                  .or(my_module_activities)
                                  .or(result_activities)
                                  .or(protocol_activities)
                                  .or(step_activities)
                                  .or(protocol_repository_activities)

      activities = activities.where.not(type_of: Extends::DASHBOARD_BLACKLIST_ACTIVITY_TYPES)
                             .select('MAX(activities.created_at) AS last_change', :subject_id, :subject_type)
                             .group(:subject_id, :subject_type)
                             .order(last_change: :desc)

      query = Activity.from("(#{activities.to_sql}) AS activities")
                      .results_joins
                      .protocols_joins
                      .my_modules_joins(:from_results, :from_protocols)
                      .experiments_joins(:from_my_modules)
                      .projects_joins(:from_experiments)
                      .repositories_joins
                      .reports_joins
                      .where('repositories.archived IS NOT TRUE')
                      .where('projects.archived IS NOT TRUE')
                      .where('experiments.archived IS NOT TRUE')
                      .where('my_modules.archived IS NOT TRUE')
                      .where('protocols.archived IS NOT TRUE')
                      .select('
                        CASE
                        WHEN my_modules.id IS NOT NULL THEN
                          CONCAT(\'tsk\', my_modules.id)
                        WHEN experiments.id IS NOT NULL THEN
                          CONCAT(\'exp\', experiments.id)
                        WHEN projects.id IS NOT NULL THEN
                          CONCAT(\'pro\', projects.id)
                        WHEN protocols.id IS NOT NULL THEN
                          CONCAT(\'prt\', COAlESCE(protocols.parent_id, protocols.id))
                        WHEN repositories.id IS NOT NULL THEN
                          CONCAT(\'inv\', repositories.id)
                        WHEN reports.id IS NOT NULL THEN
                          CONCAT(\'rpt\', reports.id)
                        END AS group_id,

                        COALESCE (
                          my_modules.name,
                          experiments.name,
                          projects.name,
                          protocols.name,
                          repositories.name,
                          reports.name
                        ) AS name,

                        reports.project_id AS report_project_id,
                        subject_id,
                        subject_type,
                        last_change
                      ')

      ordered_query = Activity.from("(#{query.to_sql}) AS activities").where.not(group_id: nil)
                              .select(:group_id,
                                      :name,
                                      'MAX(last_change) AS last_change',
                                      'MAX(report_project_id) AS report_project_id')
                              .group(:group_id, :name)
                              .order('MAX(last_change) DESC').limit(Constants::SEARCH_LIMIT)

      query_filter = "(group_id LIKE 'tsk%' OR group_id LIKE 'exp%' OR group_id LIKE 'pro%')" if @mode == 'projects'
      query_filter = "group_id LIKE 'prt%'" if @mode == 'protocols'
      query_filter = "group_id LIKE 'inv%'" if @mode == 'repositories'
      query_filter = "group_id LIKE 'rpt%'" if @mode == 'reports'
      ordered_query = ordered_query.where(query_filter) unless @mode == 'all'

      recent_objects = ordered_query.as_json.map do |recent_object|
        object_class = override_subject_type(recent_object).constantize
        recent_object.deep_symbolize_keys!
        recent_object.delete_if { |_k, v| v.nil? }

        recent_object[:last_change] = I18n.l(
          DateTime.parse(recent_object[:last_change]).in_time_zone(@user.settings[:time_zone] || 'UTC'),
          format: :full_with_comma
        )
        recent_object[:subject_type] = override_subject_type(recent_object)
        recent_object[:name] = escape_input(recent_object[:name])
        recent_object[:type] = I18n.t("activerecord.models.#{object_class.name.underscore}")
        if object_class.include?(PrefixedIdModel)
          recent_object[:code] = object_class::ID_PREFIX + recent_object[:group_id][3..]
        end
        recent_object[:url] = generate_url(recent_object)
        recent_object
      end

      recent_objects
    end

    private

    def join_project_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN projects project_subjects
        ON project_subjects.id = activities.subject_id AND activities.subject_type='Project'
        LEFT OUTER JOIN user_assignments project_user_assignments
        ON project_user_assignments.assignable_type = 'Project'
        AND project_user_assignments.assignable_id = project_subjects.id
        AND project_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles project_user_roles
        ON project_user_roles.id = project_user_assignments.user_role_id
        AND project_user_roles.permissions @> ARRAY['#{ProjectPermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_report_project_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN projects report_project_subjects
        ON report_project_subjects.id = activities.project_id AND activities.subject_type='Report'
        LEFT OUTER JOIN user_assignments report_project_user_assignments
        ON report_project_user_assignments.assignable_type = 'Project'
        AND report_project_user_assignments.assignable_id = report_project_subjects.id
        AND report_project_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles report_project_user_roles
        ON report_project_user_roles.id = report_project_user_assignments.user_role_id
        AND report_project_user_roles.permissions @> ARRAY['#{ProjectPermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_experiment_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN experiments experiment_subjects
        ON experiment_subjects.id = activities.subject_id AND activities.subject_type='Experiment'
        LEFT OUTER JOIN user_assignments experiment_user_assignments
        ON experiment_user_assignments.assignable_type = 'Experiment'
        AND experiment_user_assignments.assignable_id = experiment_subjects.id
        AND experiment_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles experiment_user_roles
        ON experiment_user_roles.id = experiment_user_assignments.user_role_id
        AND experiment_user_roles.permissions @> ARRAY['#{ExperimentPermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_my_module_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN my_modules my_module_subjects
        ON my_module_subjects.id = activities.subject_id AND activities.subject_type='MyModule'
        LEFT OUTER JOIN user_assignments my_module_user_assignments
        ON my_module_user_assignments.assignable_type = 'MyModule'
        AND my_module_user_assignments.assignable_id = my_module_subjects.id
        AND my_module_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles my_module_user_roles
        ON my_module_user_roles.id = my_module_user_assignments.user_role_id
        AND my_module_user_roles.permissions @> ARRAY['#{MyModulePermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_result_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN results result_subjects
        ON result_subjects.id = activities.subject_id AND activities.subject_type='Result'
        LEFT OUTER JOIN my_modules result_my_modules
        ON result_subjects.my_module_id = result_my_modules.id
        LEFT OUTER JOIN user_assignments result_my_module_user_assignments
        ON result_my_module_user_assignments.assignable_type = 'MyModule'
        AND result_my_module_user_assignments.assignable_id = result_my_modules.id
        AND result_my_module_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles result_my_module_user_roles
        ON result_my_module_user_roles.id = result_my_module_user_assignments.user_role_id
        AND result_my_module_user_roles.permissions @> ARRAY['#{MyModulePermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_protocol_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN protocols protocol_subjects
        ON protocol_subjects.id = activities.subject_id AND activities.subject_type='Protocol'
        LEFT OUTER JOIN my_modules protocol_my_modules
        ON protocol_subjects.my_module_id = protocol_my_modules.id
        LEFT OUTER JOIN user_assignments protocol_my_module_user_assignments
        ON protocol_my_module_user_assignments.assignable_type = 'MyModule'
        AND protocol_my_module_user_assignments.assignable_id = protocol_my_modules.id
        AND protocol_my_module_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles protocol_my_module_user_roles
        ON protocol_my_module_user_roles.id = protocol_my_module_user_assignments.user_role_id
        AND protocol_my_module_user_roles.permissions @> ARRAY['#{MyModulePermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def join_step_user_roles(activities)
      activities.joins(
        "LEFT OUTER JOIN steps step_subjects
        ON step_subjects.id = activities.subject_id AND activities.subject_type='Step'
        LEFT OUTER JOIN protocols step_protocols
        ON step_subjects.protocol_id = step_protocols.id
        LEFT OUTER JOIN my_modules step_my_modules
        ON step_protocols.my_module_id = step_my_modules.id
        LEFT OUTER JOIN user_assignments step_my_module_user_assignments
        ON step_my_module_user_assignments.assignable_type = 'MyModule'
        AND step_my_module_user_assignments.assignable_id = step_my_modules.id
        AND step_my_module_user_assignments.user_id = #{@user.id}
        LEFT OUTER JOIN user_roles step_my_module_user_roles
        ON step_my_module_user_roles.id = step_my_module_user_assignments.user_role_id
        AND step_my_module_user_roles.permissions @> ARRAY['#{MyModulePermissions::ACTIVITIES_READ}']::varchar[]"
      )
    end

    def generate_url(recent_object)
      object_id = recent_object.with_indifferent_access[:group_id].gsub(/[^0-9]/, '')

      case recent_object[:subject_type]
      when 'MyModule'
        protocols_my_module_path(object_id)
      when 'Experiment'
        my_modules_experiment_path(object_id)
      when 'Project'
        experiments_path(project_id: object_id)
      when 'Protocol'
        protocol_path(Protocol.find(object_id).latest_published_version_or_self.id)
      when 'RepositoryBase'
        repository_path(object_id)
      when 'Report'
        edit_project_report_path(recent_object[:report_project_id], object_id) if recent_object[:report_project_id]
      end
    end

    def override_subject_type(recent_object)
      group_id = recent_object.with_indifferent_access[:group_id]

      if group_id.include?('pro')
        'Project'
      elsif group_id.include?('exp')
        'Experiment'
      elsif group_id.include?('tsk')
        'MyModule'
      elsif group_id.include?('prt')
        'Protocol'
      elsif group_id.include?('inv')
        'RepositoryBase'
      elsif group_id.include?('rpt')
        'Report'
      end
    end
  end
end
