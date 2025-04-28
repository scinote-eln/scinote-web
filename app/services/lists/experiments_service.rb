# frozen_string_literal: true

module Lists
  class ExperimentsService < BaseService
    private

    def fetch_records
      @records = @raw_data.joins(:project)
                          .includes(my_modules: { my_module_status: :my_module_status_implications })
                          .includes(workflowimg_attachment: :blob, user_assignments: %i(user_role user))
                          .joins('LEFT OUTER JOIN my_modules AS active_tasks ON
                                  active_tasks.experiment_id = experiments.id
                                  AND active_tasks.archived = FALSE')
                          .joins('LEFT OUTER JOIN my_modules AS active_completed_tasks ON
                                  active_completed_tasks.experiment_id = experiments.id
                                  AND active_completed_tasks.archived = FALSE AND active_completed_tasks.state = 1')
                          .readable_by_user(@user)
                          .with_favorites(@user)
                          .select('experiments.*')
                          .select('COUNT(DISTINCT active_tasks.id) AS task_count')
                          .select('COUNT(DISTINCT active_completed_tasks.id) AS completed_task_count')
                          .group('experiments.id, favorites.id')

      view_mode = if @params[:project].archived?
                    'archived'
                  else
                    @params[:view_mode] || 'active'
                  end

      @records = @records.archived if view_mode == 'archived' && @params[:project].active?
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      if @params[:search].present?
        @records = @records.where_attributes_like(
          ['experiments.name', 'experiments.description', Experiment::PREFIXED_ID_SQL],
          @params[:search]
        )
      end

      if @filters[:query].present?
        @records = @records.where_attributes_like(
          ['experiments.name', 'experiments.description', Experiment::PREFIXED_ID_SQL],
          @filters[:query]
        )
      end

      @records = @records.where('experiments.start_on >= ?', @filters[:start_on_from]) if @filters[:start_on_from].present?

      @records = @records.where('experiments.start_on <= ?', @filters[:start_on_to]) if @filters[:start_on_to].present?

      @records = @records.where('experiments.due_date >= ?', @filters[:due_date_from]) if @filters[:due_date_from].present?

      @records = @records.where('experiments.due_date <= ?', @filters[:due_date_to]) if @filters[:due_date_to].present?

      if @filters[:updated_on_from].present?
        @records = @records.where('experiments.updated_at > ?', @filters[:updated_on_from])
      end
      if @filters[:updated_on_to].present?
        @records = @records.where('experiments.updated_at < ?',
                                @filters[:updated_on_to])
      end

      if @filters[:archived_on_from].present?
        @records = @records.where('COALESCE(experiments.archived_on, projects.archived_on) > ?',
                                @filters[:archived_on_from])
      end
      if @filters[:archived_on_to].present?
        @records = @records.where('COALESCE(experiments.archived_on, projects.archived_on) < ?',
                                @filters[:archived_on_to])
      end

      if @filters[:statuses].present?
        scopes = {
          'not_started' => @records.not_started,
          'started' => @records.started,
          'completed' => @records.completed
        }

        selected_scopes = @filters[:statuses].values.filter_map { |status| scopes[status] }

        @records = selected_scopes.reduce(@records.none, :or) if selected_scopes.any?
      end
    end

    def sortable_columns
      @sortable_columns ||= {
        created_at: 'experiments.created_at',
        name: 'experiments.name',
        code: 'experiments.id',
        archived_on: 'archived_on',
        updated_at: 'experiments.updated_at',
        completed_tasks: 'completed_task_count',
        description: 'experiments.description',
        start_date: 'start_on',
        due_date: 'due_date',
        status: 'status'
      }
    end

    def sort_records
      return unless @params[:order] && sortable_columns[order_params[:column].to_sym].present?

      @records = case order_params[:column]
                 when 'archived_on'
                   if order_params[:dir] == 'asc'
                     @records.order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) ASC'))
                             .group('experiments.archived_on', 'projects.archived_on')
                   else
                     @records.order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) DESC'))
                             .group('experiments.archived_on', 'projects.archived_on')
                   end
                 when 'status'
                   @records.order(Arel.sql("CASE
                                           WHEN experiments.started_at IS NULL AND experiments.completed_at IS NULL THEN -1
                                           WHEN experiments.completed_at IS NULL THEN 0
                                           ELSE 1 END #{sort_direction(order_params)}"))
                 else
                   sort_by = "#{sortable_columns[order_params[:column].to_sym]} #{sort_direction(order_params)}"
                   @records.order(sort_by)
                 end

      @records = @records.order(:id)
    end
  end
end
