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
                           .select('experiments.*')
                           .select('COUNT(DISTINCT active_tasks.id) AS task_count')
                           .select('COUNT(DISTINCT active_completed_tasks.id) AS completed_task_count')
                           .group('experiments.id')

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

      if @filters[:created_at_from].present?
        @records = @records.where('experiments.created_at > ?', @filters[:created_at_from])
      end
      if @filters[:created_at_to].present?
        @records = @records.where('experiments.created_at < ?',
                                @filters[:created_at_to])
      end
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
    end

    def sortable_columns
      @sortable_columns ||= {
        created_at: 'experiments.created_at',
        name: 'experiments.name',
        code: 'experiments.id',
        archived_on: 'COALESCE(experiments.archived_on, projects.archived_on)',
        updated_at: 'experiments.updated_at',
        completed_tasks: 'completed_task_count',
        description: 'experiments.description'
      }
    end
  end
end
