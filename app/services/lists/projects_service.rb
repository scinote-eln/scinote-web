module Lists
  class ProjectsService < BaseService
    include ActionView::Helpers::SanitizeHelper

    def initialize(team, user, folder, params)
      @team = team
      @user = user
      @current_folder = folder
      @params = params
      @filters = params[:filters] || {}
      @records = []
    end

    def call
      projects = fetch_projects
      folders = fetch_project_folders

      projects = filter_project_records(projects)
      folders = filter_project_folder_records(folders)

      if @filters[:folder_search].present? && @filters[:folder_search] == 'true'
        @records = projects
      else
        projects = projects.where(project_folder: @current_folder)
        folders = folders.where(parent_folder: @current_folder)

        @records = projects + folders
      end

      sort_records
      paginate_records
      @records
    end

    private

    def fetch_projects
      @team.projects
           .includes(:team, :project_comments, user_assignments: %i(user user_role))
           .with_favorites(@user)
           .visible_to(@user, @team)
           .left_outer_joins(:project_comments)
           .select('projects.*')
           .select('COUNT(DISTINCT comments.id) AS comment_count')
           .group('projects.id, favorites.id')
    end

    def fetch_project_folders
      project_folders = @team.project_folders
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

      search_query = @params[:search].presence || @filters[:query]
      records = records.where_attributes_like(['projects.name', Project::PREFIXED_ID_SQL, 'projects.description'], search_query) if search_query.present?

      if @filters[:members].present?
        records = records.joins(:user_assignments).where(user_assignments: { user_id: @filters[:members].values })
      end

      records = records.where(supervised_by_id: @filters[:head_of_project].values) if @filters[:head_of_project].present?

      records = records.where('projects.start_on >= ?', @filters[:start_on_from]) if @filters[:start_on_from].present?

      records = records.where('projects.start_on <= ?', @filters[:start_on_to]) if @filters[:start_on_to].present?

      records = records.where('projects.due_date >= ?', @filters[:due_date_from]) if @filters[:due_date_from].present?

      records = records.where('projects.due_date <= ?', @filters[:due_date_to]) if @filters[:due_date_to].present?

      if @filters[:archived_on_to].present?
        records = records.where('projects.archived_on < ?',
                                @filters[:archived_on_to])
      end
      if @filters[:archived_on_from].present?
        records = records.where('projects.archived_on > ?', @filters[:archived_on_from])
      end

      if @filters[:statuses].present?
        scopes = {
          'not_started' => records.not_started,
          'started' => records.started,
          'completed' => records.completed
        }

        selected_scopes = @filters[:statuses].values.filter_map { |status| scopes[status] }

        records = selected_scopes.reduce(records.none, :or) if selected_scopes.any?
      end

      records
    end

    def filter_project_folder_records(records)
      records = records.archived if @params[:view_mode] == 'archived'
      records = records.active if @params[:view_mode] == 'active'
      if @filters[:query].present?
        records = records.where_attributes_like(['project_folders.name', ProjectFolder::PREFIXED_ID_SQL],
                                                @filters[:query])
      end

      if @params[:search].present?
        records = records.where_attributes_like(['project_folders.name', ProjectFolder::PREFIXED_ID_SQL],
                                                @params[:search])
      end
      records
    end

    def sort_records
      return unless @params[:order]

      sort = "#{order_params[:column]}_#{sort_direction(order_params)}"

      case sort
      when 'created_at_ASC'
        @records = @records.sort_by(&:created_at).reverse!
      when 'created_at_DESC'
        @records = @records.sort_by(&:created_at)
      when 'name_ASC'
        @records = @records.sort_by { |c| c.name.downcase }
      when 'name_DESC'
        @records = @records.sort_by { |c| c.name.downcase }.reverse!
      when 'code_ASC'
        @records = @records.sort_by(&:id)
      when 'code_DESC'
        @records = @records.sort_by(&:id).reverse!
      when 'archived_on_ASC'
        @records = @records.sort_by(&:archived_on)
      when 'archived_on_DESC'
        @records = @records.sort_by(&:archived_on).reverse!
      when 'users_ASC'
        @records = @records.sort_by { |object| project_users_count(object) }
      when 'users_DESC'
        @records = @records.sort_by { |object| project_users_count(object) }.reverse!
      when 'updated_at_ASC'
        @records = @records.sort_by(&:updated_at).reverse!
      when 'updated_at_DESC'
        @records = @records.sort_by(&:updated_at)
      when 'comments_ASC'
        @records = @records.sort_by { |object| project_comments_count(object) }
      when 'comments_DESC'
        @records = @records.sort_by { |object| project_comments_count(object) }.reverse!
      when 'favorite_ASC'
        @records = @records.sort_by { |object| project_favorites(object) }
      when 'favorite_DESC'
        @records = @records.sort_by { |object| project_favorites(object) }.reverse!
      when 'start_on_ASC'
        @records = @records.sort_by { |object| project_start_on(object) }
      when 'start_on_DESC'
        @records = @records.sort_by { |object| project_start_on(object) }.reverse!
      when 'due_date_ASC'
        @records = @records.sort_by { |object| project_due_date(object) }
      when 'due_date_DESC'
        @records = @records.sort_by { |object| project_due_date(object) }.reverse!
      when 'status_ASC'
        @records = @records.sort_by { |object| project_status(object, 'asc') }
      when 'status_DESC'
        @records = @records.sort_by { |object| project_status(object, 'desc') }.reverse!
      when 'supervised_by_ASC'
        @records = @records.sort_by { |object| project_supervised_by(object, 'asc') }
      when 'supervised_by_DESC'
        @records = @records.sort_by { |object| project_supervised_by(object, 'desc') }.reverse!
      when 'description_ASC'
        @records = @records.sort_by { |object| project_description(object, 'asc') }
      when 'description_DESC'
        @records = @records.sort_by { |object| project_description(object, 'desc') }.reverse!
      end
    end

    def paginate_records
      @records = Kaminari.paginate_array(@records).page(@params[:page]).per(@params[:per_page])
    end

    def project_comments_count(object)
      project?(object) ? object.comments.count : -1
    end

    def project_users_count(object)
      project?(object) ? object.users.count : -1
    end

    def project_favorites(object)
      if project?(object)
        object.favorite ? 1 : 0
      else
        -1
      end
    end

    def project_start_on(object)
      return Date.new(2100, 1, 1) unless project?(object)

      object.start_on || Date.new(2100, 1, 1)
    end

    def project_due_date(object)
      return Date.new(2100, 1, 1) unless project?(object)

      object.due_date || Date.new(2100, 1, 1)
    end

    def project_status(object, direction)
      return (direction == 'asc' ? 10 : -1) unless project?(object)

      statuses = {
        not_started: 0,
        started: 1,
        completed: 2
      }

      statuses[object.status.to_sym]
    end

    def project_supervised_by(object, direction)
      no_value = direction == 'asc' ? 1 : 0
      has_value = direction == 'asc' ? 0 : 1

      return [no_value, ''] unless project?(object)

      if object.supervised_by
        [has_value, object.supervised_by.name]
      else
        [no_value, '']
      end
    end

    def project_description(object, direction)
      no_value = direction == 'asc' ? 1 : 0
      has_value = direction == 'asc' ? 0 : 1

      if object.description.present?
        [has_value, strip_tags(object.description)]
      else
        [no_value, '']
      end
    end

    def project?(object)
      object.instance_of?(Project)
    end
  end
end
