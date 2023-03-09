# frozen_string_literal: true

class ExperimentsOverviewService
  def initialize(project, user, params)
    @project = project
    @user = user
    @params = params
    @view_state = @project.current_view_state(@user)
    @view_mode = if @project.archived?
                   'archived'
                 else
                   params[:view_mode] || 'active'
                 end

    # Update sort if changed
    @sort = @view_state.state.dig('experiments', @view_mode, 'sort') || 'atoz'
    if @params[:sort] && @sort != @params[:sort] &&
       %w(new old atoz ztoa id_asc id_desc archived_old archived_new).include?(@params[:sort])
      @view_state.state['experiments'].merge!(Hash[@view_mode, { 'sort': @params[:sort] }.stringify_keys])
      @view_state.save!
      @sort = @view_state.state.dig('experiments', @view_mode, 'sort')
    end
  end

  def experiments
    sort_records(
      filter_records(
        fetch_records
      )
    )
  end

  private

  def fetch_records
    @project.experiments
            .joins(:project)
            .includes(my_modules: { my_module_status: :my_module_status_implications })
            .includes(workflowimg_attachment: :blob, user_assignments: %i(user_role user))
            .joins('LEFT OUTER JOIN my_modules AS active_tasks ON active_tasks.experiment_id = experiments.id ' \
                   'AND active_tasks.archived = FALSE')
            .joins('LEFT OUTER JOIN my_modules AS active_completed_tasks ON active_completed_tasks.experiment_id '\
                   '= experiments.id AND active_completed_tasks.archived = FALSE AND active_completed_tasks.state = 1')
            .readable_by_user(@user)
            .select('experiments.*')
            .select('COUNT(DISTINCT active_tasks.id) AS task_count')
            .select('COUNT(DISTINCT active_completed_tasks.id) AS completed_task_count')
            .group('experiments.id')
  end

  def filter_records(records)
    records = records.archived if @view_mode == 'archived' && @project.active?
    records = records.active if @view_mode == 'active'
    if @params[:search].present?
      records = records.where_attributes_like(
        ['experiments.name', 'experiments.description', "('EX' || experiments.id)"],
        @params[:search]
      )
    end
    if @params[:created_on_from].present?
      records = records.where('experiments.created_at > ?', @params[:created_on_from])
    end
    records = records.where('experiments.created_at < ?', @params[:created_on_to]) if @params[:created_on_to].present?
    if @params[:updated_on_from].present?
      records = records.where('experiments.updated_at > ?', @params[:updated_on_from])
    end
    records = records.where('experiments.updated_at < ?', @params[:updated_on_to]) if @params[:updated_on_to].present?

    if @params[:archived_on_from].present?
      records = records.where('COALESCE(experiments.archived_on, projects.archived_on) > ?', @params[:archived_on_from])
    end
    if @params[:archived_on_to].present?
      records = records.where('COALESCE(experiments.archived_on, projects.archived_on) < ?', @params[:archived_on_to])
    end
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
      records.group('projects.archived_on')
             .order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) ASC'))
    when 'archived_new'
      records.group('projects.archived_on')
             .order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) DESC'))
    else
      records
    end
  end
end
