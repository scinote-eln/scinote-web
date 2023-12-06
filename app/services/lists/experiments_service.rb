# frozen_string_literal: true

module Lists
  class ExperimentsService < BaseService
    private

    def fetch_records
      @raw_data = @raw_data.joins(:project)
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

      @raw_data = @raw_data.archived if view_mode == 'archived' && @params[:project].active?
      @raw_data = @raw_data.active if view_mode == 'active'

      @raw_data
    end

    def filter_records(records)
      return records unless @params[:search]

      records.where_attributes_like(
        ['experiments.name', 'experiments.description', "('EX' || experiments.id)"],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        created_at: 'experiments.created_at',
        name: 'experiments.name',
        code: 'experiments.id',
        archived_on: 'COALESCE(experiments.archived_on, projects.archived_on)'
      }
    end
  end
end
