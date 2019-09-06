# frozen_string_literal: true

class ProjectsOverviewService
  def initialize(team, user, params)
    @team = team
    @user = user
    @params = params
    @view_state = @team.current_view_state(@user)
    if @view_state.state.dig('projects', 'filter') != @params[:filter] &&
       %w(active archived all).include?(@params[:filter])
      @view_state.state['projects']['filter'] = @params[:filter]
      @view_state.save!
    end
  end

  def project_cards
    cards_state = @view_state.state.dig('projects', 'cards')
    records = fetch_records
    records = records.where(archived: true) if @params[:filter] == 'archived'
    records = records.where(archived: false) if @params[:filter] == 'active'
    if @params[:sort] &&
       cards_state['sort'] != @params[:sort] &&
       %w(new old atoz ztoa).include?(@params[:sort])
      cards_state['sort'] = @params[:sort]
      @view_state.state['projects']['cards'] = cards_state
    end
    @view_state.save! if @view_state.changed?
    case cards_state['sort']
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

  def projects_datatable
    table_state = @view_state.state.dig('projects', 'table')
    per_page = if @params[:length] && @params[:length] != '-1'
                 @params[:length].to_i
               else
                 10
               end
    if table_state['length'] != per_page
      table_state['length'] = per_page
      table_state['time'] = Time.now.to_i
      @view_state.state['projects']['table'] = table_state
      @view_state.save!
    end
    page = @params[:start] ? (@params[:start].to_i / per_page) + 1 : 1
    records = fetch_dt_records
    records = records.where(archived: true) if @params[:filter] == 'archived'
    records = records.where(archived: false) if @params[:filter] == 'active'
    search_value = @params.dig(:search, :value)
    records = search(records, search_value) if search_value.present?
    records = sort(records).page(page).per(per_page)
    records
  end

  private

  def fetch_records
    due_modules =
      MyModule.active
              .uncomplete
              .overdue
              .or(MyModule.one_day_prior)
              .distinct
              .joins(experiment: :project)
              .joins('LEFT OUTER JOIN user_projects ON '\
                'user_projects.project_id = projects.id')
              .left_outer_joins(:user_my_modules)
              .where('projects.id': @team.projects)
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
    ).joins(
      'LEFT OUTER JOIN user_projects ON user_projects.project_id = projects.id'
    ).left_outer_joins(:project_comments)

    # Only admins see all projects of the team
    unless @user.is_admin_of_team?(@team)
      projects = projects.where(
        'visibility = 1 OR user_projects.user_id = :user_id', user_id: @user.id
      )
    end
    projects
      .select('projects.*')
      .select('(SELECT COUNT(DISTINCT user_projects.id) FROM user_projects '\
        'WHERE user_projects.project_id = projects.id) AS user_count')
      .select('COUNT(DISTINCT comments.id) AS comment_count')
      .select('COUNT(DISTINCT due_modules.id) AS notification_count')
      .group('projects.id')
      .limit(1_000_000)
  end

  def fetch_dt_records
    projects = @team.projects.joins(
      'LEFT OUTER JOIN user_projects ON user_projects.project_id = projects.id'
    )
    exp_join =
      'LEFT OUTER JOIN experiments ON experiments.project_id = projects.id'\
      ' AND ((projects.archived = true)'\
      ' OR (projects.archived = false AND experiments.archived = false))'
    task_join =
      'LEFT OUTER JOIN my_modules ON my_modules.experiment_id = experiments.id'\
      ' AND ((projects.archived = true)'\
      ' OR (projects.archived = false AND my_modules.archived = false))'
    projects = projects.joins(exp_join).joins(task_join)

    # Only admins see all projects of the team
    unless @user.is_admin_of_team?(@team)
      projects = projects.where(
        'visibility = 1 OR user_projects.user_id = :user_id', user_id: @user.id
      )
    end
    projects
      .select('projects.*')
      .select('(SELECT COUNT(DISTINCT user_projects.id) FROM user_projects '\
        'WHERE user_projects.project_id = projects.id) AS user_count')
      .select('COUNT(DISTINCT experiments.id) AS experiment_count')
      .select('COUNT(DISTINCT my_modules.id) AS task_count')
      .group('projects.id')
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
      '5' => 'user_count',
      '6' => 'experiment_count',
      '7' => 'task_count'
    }
  end

  def sort(records)
    order_state = @view_state.state['projects']['table']['order'][0]
    order = @params[:order]&.values&.first
    if order
      dir = order[:dir] == 'desc' ? 'DESC' : 'ASC'
      column_index = order[:column]
    else
      dir = 'ASC'
      column_index = '1'
    end
    if order_state != [column_index.to_i, dir.downcase]
      @view_state.state['projects']['table']['order'][0] =
        [column_index.to_i, dir.downcase]
    end
    sort_column = sortable_columns[column_index]
    sort_column ||= sortable_columns['1']
    records.order("#{sort_column} #{dir}")
  end
end
