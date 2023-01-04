# frozen_string_literal: true

class ProjectsOverviewService
  def initialize(team, user, folder, params)
    @team = team
    @user = user
    @current_folder = folder
    @params = params
    @view_state = @team.current_view_state(@user)
    @view_mode = if @current_folder.present?
                   @view_mode = @current_folder.archived? ? 'archived' : 'active'
                 else
                   params[:view_mode]
                 end

    # Update sort if chanhed
    @sort = @view_state.state.dig('projects', @view_mode, 'sort') || 'atoz'
    if @params[:sort] && @sort != @params[:sort] &&
       %w(new old atoz ztoa id_asc id_desc archived_old archived_new).include?(@params[:sort])
      @view_state.state['projects'].merge!(Hash[@view_mode, { 'sort': @params[:sort] }.stringify_keys])
      @view_state.save!
      @sort = @view_state.state.dig('projects', @view_mode, 'sort')
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
      if @current_folder
        folders = if @params[:folders_search] == 'true'
                    ProjectFolder.inner_folders(@team, @current_folder).or(ProjectFolder.where(id: @current_folder.id))
                  else
                    ProjectFolder.where(id: @current_folder.id)
                  end

        fetch_project_records.where(project_folder: folders)
      elsif @params[:folders_search] == 'true'
        folders = ProjectFolder.inner_folders(@team, nil).or(ProjectFolder.where(id: nil))
        fetch_project_records
      else
        folders = ProjectFolder.where(id: nil)
        fetch_project_records.where(project_folder: @current_folder, team: @team)
      end

    project_records = sort_records(filter_project_records(project_records)).includes(:project_folder).to_a
    folder_records = folders.includes(:parent_folder).to_a

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
    @team.projects
         .includes(user_assignments: %i(user user_role), team: :user_teams)
         .includes(:project_comments, experiments: { my_modules: { my_module_status: :my_module_status_implications } })
         .visible_to(@user, @team)
         .left_outer_joins(:project_comments)
         .select('projects.*')
         .select('COUNT(DISTINCT comments.id) AS comment_count')
         .group('projects.id')
  end

  def fetch_project_folder_records
    project_folders = @team.project_folders
                           .includes(team: :user_teams)
                           .joins('LEFT OUTER JOIN project_folders child_folders
                                   ON child_folders.parent_folder_id = project_folders.id')
                           .left_outer_joins(:projects)
    project_folders.select('project_folders.*')
                   .select('COUNT(DISTINCT projects.id) AS projects_count')
                   .select('COUNT(DISTINCT child_folders.id) AS folders_count')
                   .group('project_folders.id')
  end

  def filter_project_records(records)
    records = records.archived if @view_mode == 'archived'
    records = records.active if @view_mode == 'active'
    if @params[:search].present?
      records = records.where_attributes_like(['projects.name', Project::PREFIXED_ID_SQL], @params[:search])
    end
    if @params[:members].present?
      records = records.joins(:user_assignments).where(user_assignments: { user_id: @params[:members] })
    end
    records = records.where('projects.created_at > ?', @params[:created_on_from]) if @params[:created_on_from].present?
    records = records.where('projects.created_at < ?', @params[:created_on_to]) if @params[:created_on_to].present?
    records = records.where('projects.archived_on < ?', @params[:archived_on_to]) if @params[:archived_on_to].present?
    if @params[:archived_on_from].present?
      records = records.where('projects.archived_on > ?', @params[:archived_on_from])
    end
    records
  end

  def filter_project_folder_records(records)
    records = records.archived if @view_mode == 'archived'
    records = records.active if @view_mode == 'active'
    records = records.where_attributes_like('project_folders.name', @params[:search]) if @params[:search].present?
    records
  end

  def sort_records(records)
    case @sort
    when 'new'
      records.order(created_at: :desc)
    when 'old'
      records.order(:created_at)
    when 'atoz'
      records.order(:name)
    when 'ztoa'
      records.order(name: :desc)
    when 'id_asc'
      records.order(id: :asc)
    when 'id_desc'
      records.order(id: :desc)
    when 'archived_old'
      records.order(archived_on: :asc)
    when 'archived_new'
      records.order(archived_on: :desc)
    else
      records
    end
  end

  def mixed_sort_records(records)
    case @sort
    when 'new'
      records.sort_by(&:created_at).reverse!
    when 'old'
      records.sort_by(&:created_at)
    when 'atoz'
      records.sort_by { |c| c.name.downcase }
    when 'ztoa'
      records.sort_by { |c| c.name.downcase }.reverse!
    when 'id_asc'
      records.sort_by(&:id)
    when 'id_desc'
      records.sort_by(&:id).reverse!
    when 'archived_old'
      records.sort_by(&:archived_on)
    when 'archived_new'
      records.sort_by(&:archived_on).reverse!
    end
  end
end
