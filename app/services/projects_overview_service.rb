# frozen_string_literal: true

class ProjectsOverviewService
  def initialize(team, user, folder, params)
    @team = team
    @user = user
    @current_folder = folder
    @params = params
    @view_state = @team.current_view_state(@user)

    if @view_state.state.dig('projects', 'view_mode') != @params[:filter] &&
       %w(active archived).include?(@params[:filter])
      @view_state.state['projects']['view_mode'] = @params[:filter]
      @view_state.save!
    end

    @view_mode = @view_state.state.dig('projects', 'view_mode')
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
    project_records = sort_records(filter_project_records(project_records)).includes(:project_folder).to_a
    folder_records = ProjectFolder.inner_folders(@team, @current_folder).includes(:parent_folder).to_a

    sorted_results_by_folder = {}
    build_folder_content(@current_folder, folder_records, project_records, sorted_results_by_folder)

    sorted_results_by_folder
  end

  def project_and_folder_cards
    cards = filter_project_records(fetch_project_records.where(project_folder: @current_folder)) +
            filter_project_folder_records(fetch_project_folder_records.where(parent_folder: @current_folder))

    mixed_sort_records(cards)
  end

  private

  def build_folder_content(folder, folder_records, project_records, sorted_results_by_folder)
    projects_in_folder = project_records.select { |p| p.project_folder == folder }
    sorted_results_by_folder[folder] = projects_in_folder if projects_in_folder.present?

    folder_records.select { |f| f.parent_folder == folder }.each do |inner_folder|
      build_folder_content(inner_folder, folder_records, project_records, sorted_results_by_folder)
    end
  end

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
    records = records.where_attributes_like('projects.name', @params[:search]) if @params[:search].present?
    records
  end

  def filter_project_folder_records(records)
    records = records.where(archived: true) if @params[:filter] == 'archived'
    records = records.where(archived: false) if @params[:filter] == 'active'
    records = records.where_attributes_like('project_folders.name', @params[:search]) if @params[:search].present?
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
    when 'archived_first'
      records.order(archived_on: :asc)
    when 'archived_last'
      records.order(archived_on: :desc)
    else
      records
    end
  end

  def mixed_sort_records(records)
    sort = @view_state.state.dig('projects', @view_mode, 'sort')

    if @params[:sort] && sort != @params[:sort] &&
       %w(new old atoz ztoa archived_first archived_last).include?(@params[:sort])
      @view_state.state['projects'].merge!(Hash[@view_mode, { 'sort': @params[:sort] }.stringify_keys])
    end

    if @view_state.changed?
      @view_state.save!
      sort = @view_state.state.dig('projects', @view_mode, 'sort')
    end

    case sort
    when 'new'
      records.sort_by(&:created_at).reverse!
    when 'old'
      records.sort_by(&:created_at)
    when 'atoz'
      records.sort_by { |c| c.name.downcase }
    when 'ztoa'
      records.sort_by { |c| c.name.downcase }.reverse!
    when 'archived_first'
      records.sort_by { |c| [c.class.to_s, c.archived_on] }
    when 'archived_last'
      records.sort_by { |c| [c.class.to_s, -c.archived_on.to_i] }
    end
  end
end
