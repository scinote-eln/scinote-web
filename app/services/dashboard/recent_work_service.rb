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

      activities = Activity.where(owner_id: @user.id)
                           .where('((project_id IS NULL AND team_id = ?) OR project_id IN (?))',
                                  @team.id,
                                  visible_projects.pluck(:id))
                           .select('MAX(created_at) AS last_change',
                                   :subject_id,
                                   :subject_type)
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
                      .where('projects.archived IS NOT TRUE')
                      .where('experiments.archived IS NOT TRUE')
                      .where('my_modules.archived IS NOT TRUE')
                      .where('protocols.protocol_type != ? OR protocols.protocol_type IS NULL',
                             Protocol.protocol_types[:in_repository_archived])
                      .select('
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
        recent_object.deep_symbolize_keys!
        recent_object.delete_if { |_k, v| v.nil? }

        recent_object[:last_change] = I18n.l(
          DateTime.parse(recent_object[:last_change]).in_time_zone(@user.settings[:time_zone] || 'UTC'),
          format: :full_with_comma
        )
        recent_object[:subject_type] = override_subject_type(recent_object)
        recent_object[:name] = escape_input(recent_object[:name])
        recent_object[:url] = generate_url(recent_object)
        recent_object
      end

      recent_objects
    end

    private

    def generate_url(recent_object)
      object_id = recent_object[:group_id].gsub(/[^0-9]/, '')

      case recent_object[:subject_type]
      when 'MyModule'
        protocols_my_module_path(object_id)
      when 'Experiment'
        canvas_experiment_path(object_id)
      when 'Project'
        project_path(object_id)
      when 'Protocol'
        edit_protocol_path(object_id)
      when 'Repository'
        repository_path(object_id)
      when 'Report'
        edit_project_report_path(recent_object[:report_project_id], object_id) if recent_object[:report_project_id]
      end
    end

    def override_subject_type(recent_object)
      if recent_object[:group_id].include?('pro')
        'Project'
      elsif recent_object[:group_id].include?('exp')
        'Experiment'
      elsif recent_object[:group_id].include?('tsk')
        'MyModule'
      elsif recent_object[:group_id].include?('prt')
        'Protocol'
      elsif recent_object[:group_id].include?('inv')
        'Repository'
      elsif recent_object[:group_id].include?('rpt')
        'Report'
      end
    end
  end
end
