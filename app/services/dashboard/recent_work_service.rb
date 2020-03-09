# frozen_string_literal: true

module Dashboard
  class RecentWorkService
    include InputSanitizeHelper
    include Rails.application.routes.url_helpers

    def initialize(user, team, mode)
      @user = user
      @team = team
      @mode = mode
    end

    def call
      visible_projects = Project.viewable_by_user(@user, @team)
      visible_by_team = activities_with_filter.where(project: nil, team_id: @team.id)
      visible_by_projects = activities_with_filter.where(project_id: visible_projects.pluck(:id))
      query = Activity.from("((#{visible_by_team.to_sql}) UNION ALL (#{visible_by_projects.to_sql})) AS activities")

      # Join subjects
      query = query.joins("
                        LEFT JOIN results ON
                          subject_type = 'Result'
                          AND subject_id = results.id
                        LEFT JOIN protocols ON
                          subject_type = 'Protocol'
                          AND subject_id = protocols.id
                        LEFT JOIN my_modules ON
                          (subject_type = 'MyModule' AND subject_id = my_modules.id)
                          OR  protocols.my_module_id = my_modules.id
                          OR  results.my_module_id = my_modules.id
                        LEFT JOIN experiments ON
                          (subject_type = 'Experiment' AND subject_id = experiments.id)
                          OR experiments.id = my_modules.experiment_id
                        LEFT JOIN projects ON
                          (subject_type = 'Project' AND subject_id = projects.id)
                          OR projects.id = experiments.project_id
                        LEFT JOIN repositories ON
                          subject_type = 'Repository'
                          AND subject_id = repositories.id
                        LEFT JOIN reports ON subject_type = 'Report'
                          AND subject_id = reports.id
                      ")
                   .where("
                        (projects.archived != 'true' OR projects.archived IS NULL)
                        AND (experiments.archived != 'true' OR experiments.archived IS NULL)
                        AND (my_modules.archived != 'true' OR my_modules.archived IS NULL)
                        AND (protocols.protocol_type != 4 OR protocols.protocol_type IS NULL)
                      ")
                   .select('
                        DISTINCT ON (group_id)

                        CASE
                        WHEN my_modules.id IS NOT NULL THEN
                          CONCAT(\'tsk\', my_modules.id)
                        WHEN experiments.id IS NOT NULL THEN
                          CONCAT(\'exp\', experiments.id)
                        WHEN projects.id IS NOT NULL THEN
                          CONCAT(\'pro\', projects.id)
                        WHEN protocols.id IS NOT NULL THEN
                          CONCAT(\'prt\', protocols.id)
                        WHEN repositories.id IS NOT NULL THEN
                          CONCAT(\'inv\', repositories.id)
                        WHEN reports.id IS NOT NULL THEN
                          CONCAT(\'rpt\', reports.id)
                        END as group_id,

                        CASE
                        WHEN my_modules.name IS NOT NULL THEN
                          my_modules.name
                        WHEN experiments.name IS NOT NULL THEN
                          experiments.name
                        WHEN projects.name IS NOT NULL THEN
                          projects.name
                        WHEN protocols.name IS NOT NULL THEN
                          protocols.name
                        WHEN repositories.name IS NOT NULL THEN
                          repositories.name
                        WHEN reports.name IS NOT NULL THEN
                          reports.name
                        END as name,

                        reports.project_id as report_project_id,
                        subject_id,
                        subject_type,
                        last_change
                      ')

      query_filter = []
      if %w(all projects).include? @mode
        query_filter.push("group_id LIKE '%tsk%' OR group_id LIKE '%exp%' OR group_id LIKE '%pro%'")
      end

      query_filter.push("group_id LIKE '%prt%'") if %w(all protocols).include? @mode

      query_filter.push("group_id LIKE '%inv%'") if %w(all repositories).include? @mode

      query_filter.push("group_id LIKE '%rpt%'") if %w(all reports).include? @mode

      ordered_query = Activity.from("(#{query.to_sql}) AS activities").where(query_filter.join(' OR '))
                              .order('last_change DESC').limit(Constants::SEARCH_LIMIT)

      activities = ordered_query.as_json.map do |activity|
        activity.deep_symbolize_keys!
        activity.delete_if { |_k, v| v.nil? }

        activity[:last_change] = I18n.l(
          DateTime.parse(activity[:last_change]).in_time_zone(@user.settings[:time_zone] || 'UTC'),
          format: :full_with_comma
        )
        activity[:subject_type] = override_subject_type(activity)
        activity[:name] = escape_input(activity[:name])
        activity[:url] = generate_url(activity)
        activity
      end

      activities
    end

    private

    def generate_url(activity)
      case activity[:subject_type]
      when 'MyModule'
        protocols_my_module_path(activity[:subject_id])
      when 'Experiment'
        canvas_experiment_path(activity[:subject_id])
      when 'Project'
        project_path(activity[:subject_id])
      when 'Protocol'
        edit_protocol_path(activity[:subject_id])
      when 'Repository'
        repository_path(activity[:subject_id])
      when 'Report'
        edit_project_report_path(activity[:report_project_id], activity[:subject_id]) if activity[:report_project_id]
      end
    end

    def activities_with_filter
      Activity.where("(values #>> '{message_items, user, id}') :: BIGINT = ?", @user.id)
              .select('MAX(created_at) as last_change,
                       subject_id,
                       subject_type')
              .group(:subject_id, :subject_type)
              .order(last_change: :desc)
    end

    def override_subject_type(activity)
      if activity[:group_id].include?('pro')
        'Project'
      elsif activity[:group_id].include?('exp')
        'Experiment'
      elsif activity[:group_id].include?('tsk')
        'MyModule'
      elsif activity[:group_id].include?('prt')
        'Protocol'
      elsif activity[:group_id].include?('inv')
        'Repository'
      elsif activity[:group_id].include?('rpt')
        'Report'
      end
    end
  end
end
