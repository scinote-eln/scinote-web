# frozen_string_literal: true

module Experiments
  class TableViewService
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::DateHelper
    include CommentHelper
    include ProjectsHelper
    include InputSanitizeHelper
    include BootstrapFormHelper
    include MyModulesHelper
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    COLUMNS = %i(
      task_name
      id
      due_date
      age
      results
      status
      archived
      assigned
      tags
      comments
    )

    PRELOAD = {
      results: {},
      my_module_status: {},
      tags: {},
      task_comments: {},
      user_assignments: :user,
      designated_users: {},
      experiment: :project
    }

    def initialize(experiment, my_modules, user, params)
      @my_modules = my_modules
      @page = params[:page] || 1
      @user = user
      @filters = params[:filters] || []
      @params = params
      initialize_table_sorting(experiment)
    end

    def call
      result = []
      my_module_list = @my_modules
      @filters.each do |name, value|
        my_module_list = __send__("#{name}_filter", my_module_list, value) if value.present?
      end

      my_module_list = sort_records(my_module_list)

      my_module_list = my_module_list.includes(PRELOAD)
                                     .select('my_modules.*')
                                     .group('my_modules.id')
                                     .page(@page || 1)
                                     .per(Constants::DEFAULT_ELEMENTS_PER_PAGE)
      my_module_list.each do |my_module|
        prepared_my_module = []
        COLUMNS.each do |col|
          column_data = {
            column_type: col
          }
          column_data[:data] = __send__("#{col}_presenter", my_module)
          prepared_my_module.push(column_data)
        end

        experiment = my_module.experiment
        project = experiment.project

        result.push({ id: my_module.id,
                      columns: prepared_my_module,
                      provisioning_status: my_module.provisioning_status,
                      urls: {
                        permissions: permissions_my_module_path(my_module),
                        actions_dropdown: actions_dropdown_my_module_path(my_module),
                        name_update: my_module_path(my_module),
                        restore: restore_my_modules_experiment_path(experiment),
                        provisioning_status:
                          my_module.provisioning_status == 'in_progress' &&
                            provisioning_status_my_module_url(my_module),
                        access: edit_access_permissions_project_experiment_my_module_path(project,
                                                                                          experiment, my_module)
                      } })
      end

      {
        next_page: my_module_list.next_page,
        data: result
      }
    end

    private

    def task_name_presenter(my_module)
      {
        id: my_module.id,
        name: my_module.name,
        provisioning_status: my_module.provisioning_status,
        url: protocols_my_module_path(my_module)
      }
    end

    def id_presenter(my_module)
      {
        id: my_module.id
      }
    end

    def due_date_presenter(my_module)
      {
        id: my_module.id,
        data: ApplicationController.renderer.render(
          partial: 'experiments/table_due_date.html.erb',
          locals: { my_module: my_module,
                    user: @user }
        )
      }
    end

    def archived_presenter(my_module)
      if my_module.archived?
        I18n.l(my_module.archived_on, format: :full_date)
      else
        ''
      end
    end

    def age_presenter(my_module)
      time_ago_in_words(my_module.created_at)
    end

    def results_presenter(my_module)
      {
        count: my_module.results.active.length,
        url: results_my_module_path(my_module)
      }
    end

    def status_presenter(my_module)
      {
        name: my_module.my_module_status.name,
        color: my_module.my_module_status.color
      }
    end

    def assigned_presenter(my_module)
      { html: ApplicationController.renderer.render(
        partial: 'experiments/assigned_users.html.erb',
        locals: { my_module: my_module, user: @user }
      ) }
    end

    def tags_presenter(my_module)
      {
        my_module_id: my_module.id,
        tags: my_module.tags.length,
        edit_url: my_module_tags_edit_path(my_module, format: :json)
      }
    end

    def comments_presenter(my_module)
      {
        id: my_module.id,
        count: my_module.comments.count,
        count_unseen: count_unseen_comments(my_module, @user)
      }
    end

    def name_filter(my_modules, value)
      my_modules.where_attributes_like('my_modules.name', value)
    end

    def due_date_from_filter(my_modules, value)
      my_modules.where('my_modules.due_date >= ?', value)
    end

    def due_date_to_filter(my_modules, value)
      my_modules.where('my_modules.due_date <= ?', value)
    end

    def archived_on_from_filter(my_modules, value)
      my_modules.where('my_modules.archived_on >= ?', value)
    end

    def archived_on_to_filter(my_modules, value)
      my_modules.where('my_modules.archived_on <= ?', value)
    end

    def assigned_users_filter(my_modules, value)
      my_modules.joins(:user_my_modules).where(user_my_modules: { user_id: value })
    end

    def statuses_filter(my_modules, value)
      my_modules.where(my_module_status_id: value)
    end

    def initialize_table_sorting(experiment)
      @view_state = experiment.current_view_state(@user)
      @view_mode = @params[:view_mode] || 'active'
      @sort = @view_state.state.dig('my_modules', @view_mode, 'sort') || 'atoz'
      if @params[:sort] && @sort != @params[:sort] && %w(due_first due_last atoz ztoa
                                                         archived_old archived_new).include?(@params[:sort])
        @view_state.state['my_modules'].merge!(Hash[@view_mode, { 'sort': @params[:sort] }.stringify_keys])
        @view_state.save!
        @sort = @view_state.state.dig('my_modules', @view_mode, 'sort')
      end
    end

    def sort_records(records)
      case @sort
      when 'due_first'
        records.order(:due_date)
      when 'due_last'
        records.order(Arel.sql("COALESCE(due_date, DATE '1900-01-01') DESC"))
      when 'atoz'
        records.order(:name)
      when 'ztoa'
        records.order(name: :desc)
      when 'archived_old'
        records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) ASC'))
      when 'archived_new'
        records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) DESC'))
      else
        records
      end
    end
  end
end
