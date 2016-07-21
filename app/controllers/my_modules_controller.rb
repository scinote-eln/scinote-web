class MyModulesController < ApplicationController
  include SampleActions

  before_action :load_vars, only: [
    :show, :edit, :update, :destroy,
    :description, :due_date, :protocols, :results,
    :samples, :activities, :activities_tab,
    :assign_samples, :unassign_samples,
    :delete_samples,
    :samples_index, :archive]
  before_action :load_markdown, only: [ :results ]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :check_edit_permissions, only: [
    :edit, :update, :description, :due_date
  ]
  before_action :check_destroy_permissions, only: [:destroy]
  before_action :check_view_info_permissions, only: [:show]
  before_action :check_view_activities_permissions, only: [:activities, :activities_tab]
  before_action :check_view_protocols_permissions, only: [:protocols]
  before_action :check_view_results_permissions, only: [:results]
  before_action :check_view_samples_permissions, only: [:samples, :samples_index]
  before_action :check_view_archive_permissions, only: [:archive]
  before_action :check_assign_samples_permissions, only: [:assign_samples]
  before_action :check_unassign_samples_permissions, only: [:unassign_samples]

  layout "fluid"

  # Define submit actions constants (used in routing)
  ASSIGN_SAMPLES = 'Assign'
  UNASSIGN_SAMPLES = 'Unassign'

  # Action defined in SampleActions
  DELETE_SAMPLES = 'Delete'

  def show
    respond_to do |format|
      format.html
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "show.html.erb"
          })
        }
      }
    end
  end

  # Description modal window in full-zoom canvas
  def description
    respond_to do |format|
      format.html
      format.json {
        render json: {
          html: render_to_string({
            partial: "description.html.erb"
          }),
          title: t("my_modules.description.title", module: @my_module.name)
        }
      }
    end
  end

  def activities
    @last_activity_id = params[:from].to_i || 0
    @per_page = 10

    @activities = @my_module.last_activities(@last_activity_id, @per_page +1 )
    @more_activities_url = ""

    @overflown = @activities.length > @per_page

    @activities = @my_module.last_activities(@last_activity_id, @per_page)

    if @activities.count > 0
      @more_activities_url = url_for(
        controller: 'my_modules',
        action: 'activities',
        format: :json,
        from: @activities.last.id)
    end

    respond_to do |format|
      format.html
      format.json {
        # 'activites' partial includes header and form for adding older
        # activities. 'list' partial is used for showing more activities.
        partial = "activities.html.erb"
        if @activities.last.id > 0
          partial = "my_modules/activities/list_activities.html.erb"
        end
        render :json => {
          :per_page => @per_page,
          :results_number => @activities.length,
          :more_url => @more_activities_url,
          :html => render_to_string({
            :partial => partial
          })
        }
      }
    end
  end

  # Different controller for showing activities inside tab
  def activities_tab
    @activities = @my_module.last_activities(1, @per_page)

    respond_to do |format|
      format.html
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "activities.html.erb"
          })
        }
      }
    end
  end

  # Due date modal window in full-zoom canvas
  def due_date
    respond_to do |format|
      format.html
      format.json {
        render json: {
          html: render_to_string({
            partial: "due_date.html.erb"
          }),
          title: t("my_modules.due_date.title", module: @my_module.name)
        }
      }
    end
  end

  def edit
    session[:return_to] ||= request.referer
  end

  def update
    @my_module.assign_attributes(my_module_params)
    @my_module.last_modified_by = current_user

    description_changed = @my_module.description_changed?

    if @my_module.archived_changed?(from: false, to: true)
      saved = @my_module.archive(current_user)
      if saved
        # Currently not in use
        Activity.create(
          type_of: :archive_module,
          project: @my_module.project,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.archive_module',
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    elsif @my_module.archived_changed?(from: true, to: false)
      saved = @my_module.restore(current_user)
      if saved
        Activity.create(
          type_of: :restore_module,
          project: @my_module.project,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.restore_module',
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    else
      saved = @my_module.save

      if saved and description_changed then
        Activity.create(
          type_of: :change_module_description,
          project: @my_module.project,
          my_module: @my_module,
          user: current_user,
          message: t(
            "activities.change_module_description",
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    end

    respond_to do |format|
      if saved
        format.html {
          flash[:success] = t("my_modules.update.success_flash",
            module: @my_module.name)
          redirect_to(:back)
        }
        format.json {
          alerts = []
          alerts << "alert-red" if @my_module.is_overdue?
          alerts << "alert-yellow" if @my_module.is_one_day_prior?
          render json: {
            status: :ok,
            due_date_label: render_to_string(
              partial: "my_modules/due_date_label.html.erb",
              locals: { my_module: @my_module }
            ),
            module_header_due_date_label: render_to_string(
              partial: "my_modules/module_header_due_date_label.html.erb",
              locals: { my_module: @my_module }
            ),
            description_label: render_to_string(
              partial: "my_modules/description_label.html.erb",
              locals: { my_module: @my_module }
            ),
            alerts: alerts
          }
        }
      else
        format.html {
          render :edit
        }
        format.json {
          render json: @project.errors,
            status: :unprocessable_entity
        }
      end
    end
  end

  def protocols
    @protocol = @my_module.protocol
  end

  def results

  end

  def samples
    @samples_index_link = samples_index_my_module_path(@my_module, format: :json)
    @organization = @my_module.project.organization
  end

  def archive
    @archived_results = @my_module.archived_results
  end

  # Submit actions
  def assign_samples
    if params[:sample_ids].present?
      samples = []

      params[:sample_ids].each do |id|
        sample = Sample.find_by_id(id)
        sample.last_modified_by = current_user
        sample.save

        if sample
          samples << sample
        end
      end

      @my_module.get_downstream_modules.each do |my_module|
        new_samples = samples.select { |el| my_module.samples.exclude?(el) }
        my_module.samples.push(*new_samples)
      end
    end
    redirect_to samples_my_module_path(@my_module)
  end

  def unassign_samples
    if params[:sample_ids].present?
      samples = []

      params[:sample_ids].each do |id|
        sample = Sample.find_by_id(id)
        sample.last_modified_by = current_user
        sample.save

        if sample
          samples << sample
        end
      end

      @my_module.get_downstream_modules.each do |my_module|
        my_module.samples.destroy(samples & my_module.samples)
      end
    end
    redirect_to samples_my_module_path(@my_module)
  end

  # AJAX actions
  def samples_index
    @organization = @my_module.project.organization

    respond_to do |format|
      format.html
      format.json {
        render json: ::SampleDatatable.new(view_context, @organization, nil, @my_module)
      }
    end
  end

  private

  def load_vars
    @direct_upload = ENV['PAPERCLIP_DIRECT_UPLOAD'] == "true"
    @my_module = MyModule.find_by_id(params[:id])
    if @my_module
      @project = @my_module.project
    else
      render_404
    end
  end

  # Initialize markdown parser
  def load_markdown
    @markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        filter_html: true,
        no_images: true
      )
    )
  end

  def check_edit_permissions
    unless can_edit_module(@my_module)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_archive_module(@my_module)
      render_403
    end
  end

  def check_view_info_permissions
    unless can_view_module_info(@my_module)
      render_403
    end
  end

  def check_view_activities_permissions
    unless can_view_module_activities(@my_module)
      render_403
    end
  end

  def check_view_protocols_permissions
    unless can_view_module_protocols(@my_module)
      render_403
    end
  end

  def check_view_results_permissions
    unless can_view_results_in_module(@my_module)
      render_403
    end
  end

  def check_view_samples_permissions
    unless can_view_module_samples(@my_module)
      render_403
    end
  end

  def check_view_archive_permissions
    unless can_view_module_archive(@my_module)
      render_403
    end
  end

  def check_assign_samples_permissions
    unless can_add_samples_to_module(@my_module)
      render_403
    end
  end

  def check_unassign_samples_permissions
    unless can_delete_samples_from_module(@my_module)
      render_403
    end
  end

  def my_module_params
    params.require(:my_module).permit(:name, :description, :due_date,
      :archived)
  end
end
