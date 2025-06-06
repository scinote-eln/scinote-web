# frozen_string_literal: true

module Lists
  class ProjectsService < BaseService
    include ActionView::Helpers::SanitizeHelper
    include Canaid::Helpers::PermissionsHelper

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
      done_status_id = MyModuleStatusFlow.first.final_status.id
      @team.projects
           .includes(:team, :project_comments, user_assignments: %i(user user_role))
           .joins('LEFT OUTER JOIN experiments AS active_experiments ON
                   active_experiments.project_id = projects.id
                   AND active_experiments.archived = FALSE')
           .joins('LEFT OUTER JOIN experiments AS active_completed_experiments ON
                   active_completed_experiments.project_id = projects.id
                   AND active_completed_experiments.archived = FALSE AND active_completed_experiments.done_at IS NOT NULL')
           .joins('LEFT OUTER JOIN my_modules AS active_tasks ON
                   active_tasks.experiment_id = active_experiments.id
                   AND active_tasks.archived = FALSE')
           .joins(
             ActiveRecord::Base.sanitize_sql_array([
                                                     'LEFT OUTER JOIN my_modules AS active_completed_tasks ON
               active_completed_tasks.experiment_id = active_experiments.id
               AND active_completed_tasks.archived = FALSE AND active_completed_tasks.my_module_status_id = ?',
                                                     done_status_id
                                                   ])
           )
           .with_favorites(@user)
           .visible_to(@user, @team)
           .left_outer_joins(:project_comments)
           .select('projects.*')
           .select('COUNT(DISTINCT comments.id) AS comment_count')
           .select('COUNT(DISTINCT active_experiments.id) AS experiments_count')
           .select('COUNT(DISTINCT active_completed_experiments.id) AS completed_experiments_count')
           .select('COUNT(DISTINCT active_tasks.id) AS tasks_count')
           .select('COUNT(DISTINCT active_completed_tasks.id) AS completed_tasks_count')
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

      records = records.joins(:user_assignments).where(user_assignments: { user_id: @filters[:members].values }) if @filters[:members].present?

      records = records.where(supervised_by_id: @filters[:head_of_project].values) if @filters[:head_of_project].present?

      records = records.where(projects: { start_date: (@filters[:start_date_from]).. }) if @filters[:start_date_from].present?

      records = records.where(projects: { start_date: ..(@filters[:start_date_to]) }) if @filters[:start_date_to].present?

      records = records.where(projects: { due_date: (@filters[:due_date_from]).. }) if @filters[:due_date_from].present?

      records = records.where(projects: { due_date: ..(@filters[:due_date_to]) }) if @filters[:due_date_to].present?

      records = records.where(projects: { archived_on: ...(@filters[:archived_on_to]) }) if @filters[:archived_on_to].present?
      records = records.where('projects.archived_on > ?', @filters[:archived_on_from]) if @filters[:archived_on_from].present?

      if @filters[:statuses].present?
        scopes = {
          'not_started' => records.not_started,
          'in_progress' => records.in_progress,
          'done' => records.done
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
      when 'start_date_ASC'
        @records = @records.sort_by { |object| project_start_date(object) }
      when 'start_date_DESC'
        @records = @records.sort_by { |object| project_start_date(object) }.reverse!
      when 'due_date_ASC'
        @records = @records.sort_by { |object| project_due_date(object) }
      when 'due_date_DESC'
        @records = @records.sort_by { |object| project_due_date(object) }.reverse!
      when 'status_ASC'
        @records = @records.sort_by { |object| project_status(object, 'asc') }
      when 'status_DESC'
        @records = @records.sort_by { |object| project_status(object, 'desc') }.reverse!
      when 'supervised_by_ASC'
        @records = @records.sort_by { |object| project_supervised_by(object) }
      when 'supervised_by_DESC'
        @records = @records.sort_by { |object| project_supervised_by(object) }.reverse!
      when 'description_ASC'
        @records = @records.sort_by { |object| project_description(object) }
      when 'description_DESC'
        @records = @records.sort_by { |object| project_description(object) }.reverse!
      end
    end

    def paginate_records
      @records = Kaminari.paginate_array(@records).page(@params[:page]).per(@params[:per_page])
    end

    def project_comments_count(object)
      return [0, 0, -1] unless project?(object)

      [1, can_create_project_comments?(@user, object) ? 1 : 0, object.comments.count]
    end

    def project_users_count(object)
      return [0, -1] unless project?(object)

      [1, object.users.count]
    end

    def project_favorites(object)
      if project?(object)
        object.favorite ? 1 : 0
      else
        -1
      end
    end

    def project_start_date(object)
      return Date.new(2100, 1, 1) unless project?(object)

      object.start_date || Date.new(2100, 1, 1)
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

    def project_supervised_by(object)
      return [1, '', 1] unless project?(object)

      [object.supervised_by_id ? 0 : 1, object.supervised_by&.full_name || '', 0]
    end

    def project_description(object)
      return [1, '', 1] unless project?(object)

      [object.description ? 0 : 1, strip_tags(object.description || ''), 0]
    end

    def project?(object)
      object.instance_of?(Project)
    end
  end
end
