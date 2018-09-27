# frozen_string_literal: true

class ProjectsOverviewService
  def initialize(team, user)
    @team = team
    @user = user
  end

  def project_cards(params)
    records = fetch_records
    records = records.where(archived: true) if params[:filter] == 'archived'
    records = records.where(archived: false) if params[:filter] == 'active'
    return records unless params[:sort]
    case params[:sort]
    when 'new'
      records.order(created_at: :desc)
    when 'old'
      records.order(:created_at)
    when 'atoz'
      records.order(:name)
    when 'ztoa'
      records.order(name: :desc)
    else
      records
    end
  end

  def projects_datatable(params)
    per_page = params[:length] == '-1' ? 10 : params[:length].to_i
    page = params[:start] ? (params[:start].to_i / per_page) + 1 : 1
    records = fetch_dt_records
    records = records.where(archived: true) if params[:filter] == 'archived'
    records = records.where(archived: false) if params[:filter] == 'active'
    search_value = params.dig(:search, :value)
    records = search(records, search_value) if search_value.present?
    sort(records, params).page(page).per(per_page)
  end

  private

  def fetch_records
    due_modules =
      MyModule.active
              .overdue
              .or(MyModule.one_day_prior)
              .distinct
              .joins(experiment: :project)
              .joins('LEFT OUTER JOIN user_projects ON '\
                'user_projects.project_id = projects.id')
              .left_outer_joins(:user_my_modules)
              .where('user_my_modules.user_id = :user_id '\
                'OR (user_projects.role = 0 '\
                'AND user_projects.user_id = :user_id)', user_id: @user.id)
              .select('my_modules.id', 'my_modules.experiment_id')
    projects = @team.projects.joins(
      'LEFT OUTER JOIN experiments ON experiments.project_id = projects.id '\
      'AND experiments.archived = false'
    ).joins(
      "LEFT OUTER JOIN (#{due_modules.to_sql}) due_modules "\
      "ON due_modules.experiment_id = experiments.id"
    ).left_outer_joins(:user_projects, :project_comments)

    # Only admins see all projects of the team
    unless @user.is_admin_of_team?(@team)
      projects = projects.where(
        'visibility = 1 OR user_projects.user_id = :user_id', user_id: @user.id
      )
    end
    projects = projects
               .select('projects.*')
               .select('COUNT(DISTINCT user_projects.id) AS user_count')
               .select('COUNT(DISTINCT comments.id) AS comment_count')
               .select('COUNT(DISTINCT due_modules.id) AS notification_count')
               .group('projects.id')
               .limit(1_000_000)
    Project.from(projects, 'projects')
  end

  def fetch_dt_records
    projects = @team.projects.joins(
      'LEFT OUTER JOIN user_projects ON user_projects.project_id = projects.id'
    ).joins(
      'LEFT OUTER JOIN experiments ON experiments.project_id = projects.id'\
      ' AND experiments.archived = projects.archived'
    ).joins(
      'LEFT OUTER JOIN my_modules ON my_modules.experiment_id = experiments.id'\
      ' AND my_modules.archived = projects.archived'
    )

    # Only admins see all projects of the team
    unless @user.is_admin_of_team?(@team)
      projects = projects.where(
        'visibility = 1 OR user_projects.user_id = :user_id', user_id: @user.id
      )
    end
    projects = projects
               .select('projects.*')
               .select('COUNT(DISTINCT user_projects.id) AS user_count')
               .select('COUNT(DISTINCT experiments.id) AS experiment_count')
               .select('COUNT(DISTINCT my_modules.id) AS task_count')
               .group('projects.id')
    Project.from(projects, 'projects')
  end

  def search(records, value)
    records.where_attributes_like('projects.name', value)
  end

  def sortable_columns
    {
      '1' => 'projects.archived',
      '2' => 'projects.name',
      '3' => 'projects.created_at',
      '4' => 'projects.visibility',
      '5' => 'projects.user_count',
      '6' => 'projects.experiment_count',
      '7' => 'projects.task_count'
    }
  end

  def sort(records, params)
    order = params[:order]&.values&.first
    if order
      dir = order[:dir] == 'DESC' ? 'DESC' : 'ASC'
      column_index = order[:column]
    else
      dir = 'ASC'
      column_index = '1'
    end
    sort_column = sortable_columns[column_index]
    sort_column ||= sortable_columns['1']
    records.order("#{sort_column} #{dir}")
  end
end
