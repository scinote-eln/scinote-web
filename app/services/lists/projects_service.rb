module Lists
  class ProjectsService < BaseService
    attr_accessor :page_dict

    SELECT_ATTRIBUTES = %w(id team_id created_at archived_on updated_at name).freeze

    def initialize(team, user, folder, params)
      @team = team
      @user = user
      @current_folder = folder
      @params = params
      @filters = params[:filters] || {}
      @records = []
      @page_dict = {}
    end

    def call
      projects = projects_data
      folders = project_folders_data

      projects = filter_project_records(projects)
      folders = filter_project_folder_records(folders)

      if @filters[:folder_search].present? && @filters[:folder_search] == 'true'
        @records = projects
      else
        projects = projects.where(project_folder: @current_folder)
        folders = folders.where(parent_folder: @current_folder)

        @records = Project.from("((#{projects.to_sql}) UNION ALL (#{folders.to_sql})) AS projects")
      end

      sort_records
      paginate_records
      page_dict_params
      convert_data
      @records
    end

    private

    def projects_data
      @team.projects
           .visible_to(@user, @team)
           .left_outer_joins(:project_comments)
           .joins(:user_assignments)
           .select(SELECT_ATTRIBUTES.map { |attribute| "projects.#{attribute}" }.join(','))
           .select('COUNT(DISTINCT user_assignments.id) AS user_assignments_count',
                   'COUNT(DISTINCT comments.id) AS comment_count',
                   '1 as type')
           .group('projects.id')
    end

    def project_folders_data
      @team.project_folders
           .select(SELECT_ATTRIBUTES.map { |attribute| "project_folders.#{attribute}" }.join(','))
           .select('-1 AS user_assignments_count',
                   '-1 AS comment_count',
                   '0 AS type')
           .group('project_folders.id')
    end

    def fetch_projects
      @team.projects
           .where(id: @records.select { |record| record.type.positive? })
           .includes(:team, :project_comments, user_assignments: %i(user user_role))
           .visible_to(@user, @team)
           .left_outer_joins(:project_comments)
           .select('projects.*')
           .select('COUNT(DISTINCT comments.id) AS comment_count')
           .group('projects.id')
    end

    def fetch_project_folders
      project_folders = @team.project_folders
                             .where(id: @records.select { |record| record.type.zero? })
                             .includes(:team)
                             .joins('LEFT OUTER JOIN project_folders child_folders
                                    ON child_folders.parent_folder_id = project_folders.id')
                             .left_outer_joins(:projects)
      project_folders.select('project_folders.*')
                     .select('COUNT(DISTINCT projects.id) AS projects_count')
                     .select('COUNT(DISTINCT child_folders.id) AS folders_count')
                     .group('project_folders.id')
    end

    def filter_project_records(records)
      records = records.archived if @params[:view_mode] == 'archived'
      records = records.active if @params[:view_mode] == 'active'

      if @params[:search].present?
        records = records.where_attributes_like(['projects.name', Project::PREFIXED_ID_SQL], @params[:search])
      end

      if @filters[:query].present?
        records = records.where_attributes_like(['projects.name', Project::PREFIXED_ID_SQL], @filters[:query])
      end

      if @filters[:members].present?
        records = records.joins(:user_assignments).where(user_assignments: { user_id: @filters[:members].values })
      end
      if @filters[:created_at_from].present?
        records = records.where('projects.created_at > ?',
                                @filters[:created_at_from])
      end
      records = records.where('projects.created_at < ?', @filters[:created_at_to]) if @filters[:created_at_to].present?
      if @filters[:archived_on_to].present?
        records = records.where('projects.archived_on < ?',
                                @filters[:archived_on_to])
      end
      if @filters[:archived_on_from].present?
        records = records.where('projects.archived_on > ?', @filters[:archived_on_from])
      end
      records
    end

    def filter_project_folder_records(records)
      records = records.archived if @params[:view_mode] == 'archived'
      records = records.active if @params[:view_mode] == 'active'
      records = records.where_attributes_like('project_folders.name', @filters[:query]) if @filters[:query].present?
      records = records.where_attributes_like('project_folders.name', @params[:search]) if @params[:search].present?
      records
    end

    def sort_records
      return unless @params[:order]

      case order_params[:column]
      when 'created_at'
        @records = @records.order(created_at: sort_direction(order_params))
      when 'name'
        @records = @records.order(name: sort_direction(order_params))
      when 'code'
        @records = @records.order(id: sort_direction(order_params))
      when 'archived_on'
        @records = @records.order(archived_on: sort_direction(order_params))
      when 'users'
        @records = @records.order(user_assignments_count: sort_direction(order_params))
      when 'updated_at'
        @records = @records.order(updated_at: sort_direction(order_params))
      when 'comments'
        @records = @records.order(comment_count: sort_direction(order_params))
      end
    end

    def paginate_records
      @records = Kaminari.paginate_array(@records).page(@params[:page]).per(@params[:per_page])
    end

    def convert_data
      projects = fetch_projects.index_by(&:id)
      project_folders = fetch_project_folders.index_by(&:id)

      @records = @records.map do |record|
        if record.type.positive?
          projects[record.id]
        else
          project_folders[record.id]
        end
      end
    end

    def page_dict_params
      @page_dict = {
        current_page: @records.current_page,
        next_page: @records.next_page,
        prev_page: @records.prev_page,
        total_pages: @records.total_pages,
        total_count: @records.total_count
      }
    end
  end
end
