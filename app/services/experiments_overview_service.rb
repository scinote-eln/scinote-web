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
       %w(new old atoz ztoa archived_old archived_new).include?(@params[:sort])
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
    @project.experiments.joins(:project)
  end

  def filter_records(records)
    records = records.archived if @view_mode == 'archived' && @project.active?
    records = records.active if @view_mode == 'active'
    if @params[:search].present?
      records = records.where_attributes_like(%w(experiments.name experiments.description), @params[:search])
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
    when 'archived_old'
      records.order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) ASC'))
    when 'archived_new'
      records.order(Arel.sql('COALESCE(experiments.archived_on, projects.archived_on) DESC'))
    else
      records
    end
  end
end
