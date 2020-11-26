# frozen_string_literal: true

class ProjectsOverviewService
  def initialize(team, user, folder, params)
    @team = team
    @user = user
    @current_folder = folder
    @params = params
    @view_state = @team.current_view_state(@user)
    if @view_state.state.dig('projects', 'filter') != @params[:filter] &&
       %w(active archived all).include?(@params[:filter])
      @view_state.state['projects']['filter'] = @params[:filter]
      @view_state.save!
    end
  end

  def project_cards
    sort_records(
      filter_project_records(
        fetch_project_records.where(project_folder: @current_folder)
      )
    )
  end

  def project_folder_cards
    sort_records(
      filter_project_folder_records(
        fetch_project_folder_records.where(parent_folder: @current_folder)
      )
    )
  end

  def grouped_by_folder_project_cards
    project_records =
      if @current_folder.present?
        fetch_project_records.where(project_folder: ProjectFolder.inner_folders(@team, @current_folder))
      else
        fetch_project_records
      end
    project_records = project_records.includes(:project_folder)
    sort_records(filter_project_records(project_records)).group_by(&:project_folder)
  end

  def project_and_folder_cards
    cards = filter_project_records(fetch_project_records) + filter_project_folder_records(fetch_project_folder_records)

    mixed_sort_records(cards)
  end

  private

  def fetch_project_records
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
  end

  def fetch_project_folder_records
    project_folders = @team.project_folders.left_outer_joins(:projects, :project_folders)
    project_folders.select('project_folders.*')
                   .select('COUNT(DISTINCT projects.id) AS projects_count')
                   .select('COUNT(DISTINCT project_folders.id) AS folders_count')
                   .group('project_folders.id')
  end

  def filter_project_records(records)
    records = records.where(archived: true) if @params[:filter] == 'archived'
    records = records.where(archived: false) if @params[:filter] == 'active'
    records = Project.search_by_name(@user, @team, @params[:search]) if @params[:search].present?
    records
  end

  def filter_project_folder_records(records)
    records = ProjectFolder.search_by_name(@user, @team, @params[:search]) if @params[:search].present?
    records
  end

  def sort_records(records)
    cards_state = @view_state.state.dig('projects', 'cards')
    if @params[:sort] && cards_state['sort'] != @params[:sort] && %w(new old atoz ztoa).include?(@params[:sort])
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

  def mixed_sort_records(records)
    cards_state = @view_state.state.dig('projects', 'cards')
    if @params[:sort] && cards_state['sort'] != @params[:sort] && %w(new old atoz ztoa).include?(@params[:sort])
      cards_state['sort'] = @params[:sort]
      @view_state.state['projects']['cards'] = cards_state
    end
    @view_state.save! if @view_state.changed?

    case cards_state['sort']
    when 'new'
      records.sort_by(&:created_at).reverse!
    when 'old'
      records.sort_by(&:created_at)
    when 'atoz'
      records.sort_by { |c| c.name.downcase }
    when 'ztoa'
      records.sort_by { |c| c.name.downcase }.reverse!
    else
      records
    end
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
end
