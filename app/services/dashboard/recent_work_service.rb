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
      if %w(all projects).include? @mode
        query = query.joins("
                        LEFT JOIN projects ON
                          subject_type = 'Project'
                          AND subject_id = projects.id
                          AND projects.archived = 'false'
                        LEFT JOIN experiments ON
                          subject_type = 'Experiment'
                          AND subject_id = experiments.id
                          AND experiments.archived = 'false'
                        LEFT JOIN my_modules ON
                          subject_type = 'MyModule'
                          AND subject_id = my_modules.id
                          AND my_modules.archived = 'false'
                        LEFT JOIN results ON
                          subject_type = 'Result'
                          AND subject_id = results.id
                        LEFT JOIN my_modules my_modules_result ON
                          my_modules_result.id = results.my_module_id
                          AND my_modules_result.archived = 'false'
                        LEFT JOIN my_modules my_modules_protocol ON
                          subject_type = 'Protocol'
                          AND (values #>> '{message_items, my_module, id}') :: BIGINT = my_modules_protocol.id
                          AND my_modules_protocol.archived = 'false'
                      ").select('
                        projects.name as project_name,
                        experiments.name as experiment_name,
                        my_modules.name as my_module_name,
                        my_modules_protocol.name as my_module_protocol_name,
                        my_modules_protocol.id as my_module_protocol_id,
                        my_modules_result.name as my_module_result_name,
                        my_modules_result.id as my_module_result_id
                      ')
      end

      if %w(all protocols).include? @mode
        query = query.joins("LEFT JOIN protocols ON subject_type = 'Protocol'
                                                    AND subject_id = protocols.id AND protocols.my_module_id IS NULL
                                                    AND protocols.protocol_type != 4")
                     .select('protocols.name as protocol_name')
      end

      if %w(all repositories).include? @mode
        query = query.joins("LEFT JOIN repositories ON subject_type = 'Repository' AND subject_id = repositories.id")
                     .select('repositories.name as repository_name')
      end

      if %w(all reports).include? @mode
        query = query.joins("LEFT JOIN reports ON subject_type = 'Report' AND subject_id = reports.id")
                     .select('reports.name as report_name, reports.project_id as report_project_id')
      end

      query = query.select(:subject_id, :subject_type, :last_change).order(last_change: :desc)

      activities = query.as_json.map do |activity|
        activity.deep_symbolize_keys!
        object_name = nil
        activity.delete_if { |_k, v| v.nil? }
        if activity[:my_module_protocol_name]
          activity[:subject_type] = 'MyModule'
          activity[:subject_id] = activity.delete :my_module_protocol_id
        end
        if activity[:my_module_result_name]
          activity[:subject_type] = 'MyModule'
          activity[:subject_id] = activity.delete :my_module_result_id
        end
        activity.each do |key, _value|
          object_name = activity.delete key if key.to_s.include? 'name'
        end
        activity[:last_change] = I18n.l(
          DateTime.parse(activity[:last_change]).in_time_zone(@user.settings[:time_zone] || 'UTC'),
          format: :full_with_comma
        )
        activity[:name] = escape_input(object_name)
        activity[:url] = generate_url(activity)
        activity unless activity[:name].empty?
      end.compact

      activities.uniq! { |activity| [activity[:subject_type], activity[:subject_id]].join(':') }

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
      Activity.where('created_at > ?', (DateTime.now - 1.month))
              .where("(values #>> '{message_items, user, id}') :: BIGINT = ?", @user.id)
              .select('MAX(created_at) as last_change,
                       percentile_disc(0) WITHIN GROUP (ORDER BY values) as values,
                       subject_id,
                       subject_type')
              .group(:subject_id, :subject_type)
              .order(last_change: :desc)
    end
  end
end
