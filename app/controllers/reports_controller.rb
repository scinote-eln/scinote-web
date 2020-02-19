class ReportsController < ApplicationController
  include TeamsHelper
  include ReportActions
  # Ignore CSRF protection just for PDF generation (because it's
  # used via target='_blank')
  protect_from_forgery with: :exception, except: :generate

  BEFORE_ACTION_METHODS = %i(
    new
    create
    edit
    update
    generate
    save_modal
    project_contents_modal
    experiment_contents_modal
    module_contents_modal
    step_contents_modal
    result_contents_modal
    project_contents
    experiment_contents
    module_contents
    step_contents
    result_contents
  ).freeze

  before_action :load_vars, only: %i(edit update)
  before_action :load_vars_nested, only: BEFORE_ACTION_METHODS
  before_action :load_visible_projects, only: %i(index visible_projects)
  before_action :load_available_repositories,
                only: %i(new edit available_repositories)

  before_action :check_manage_permissions, only: BEFORE_ACTION_METHODS

  # Index showing all reports of a single project
  def index; end

  def datatable
    respond_to do |format|
      format.json do
        render json: ::ReportDatatable.new(
          view_context,
          current_user,
          Report.viewable_by_user(current_user, current_team)
        )
      end
    end
  end

  # Report grouped by modules
  def new
    @report = nil
  end

  # Creating new report from the _save modal of the new page
  def create
    continue = true
    begin
      report_contents = JSON.parse(params.delete(:report_contents))
    rescue
      continue = false
    end

    @report = Report.new(report_params)
    @report.project = @project
    @report.user = current_user
    @report.team = current_team
    @report.last_modified_by = current_user

    if continue && @report.save_with_contents(report_contents)
      log_activity(:create_report)

      respond_to do |format|
        format.json do
          render json: { url: reports_path }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @report.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    # cleans all the deleted report
    current_team_switch(@report.project.team)
    @report.cleanup_report
    render 'reports/new.html.erb'
  end

  # Updating existing report from the _save modal of the new page
  def update
    continue = true
    begin
      report_contents = JSON.parse(params.delete(:report_contents))
    rescue
      continue = false
    end

    @report.last_modified_by = current_user
    @report.assign_attributes(report_params)

    if continue && @report.save_with_contents(report_contents)
      log_activity(:edit_report)

      respond_to do |format|
        format.json do
          render json: { url: reports_path }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @report.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # Destroy multiple entries action
  def destroy
    begin
      report_ids = JSON.parse(params[:report_ids])
    rescue
      render_404
    end

    report_ids.each do |report_id|
      report = Report.find_by_id(report_id)
      next unless report.present? && can_manage_reports?(report.project.team)

      # record an activity
      log_activity(:delete_report, report)
      report.destroy
    end

    redirect_to reports_path
  end

  # Generation action
  # Currently, only .PDF is supported
  def generate
    content = params[:data]
    content = I18n.t('projects.reports.new.no_content_for_PDF_html') if content.blank?
    respond_to do |format|
      format.pdf do
        render pdf: 'report', header: { right: '[page] of [topage]' },
                              locals: { content: content },
                              template: 'reports/report.pdf.erb',
                              disable_javascript: true
      end
      format.docx do
        @user = current_user
        @team = current_team
        @scinote_url = root_url
        @data = params[:data]
        headers["Content-Disposition"] = 'attachment; filename="scinote_report.docx"'
      end
    end
  end

  def save_pdf_to_inventory_item
    save_pdf_to_inventory_item = ReportActions::SavePdfToInventoryItem.new(
      current_user, current_team, save_PDF_params
    )
    if save_pdf_to_inventory_item.save
      render json: {
        message: I18n.t(
          'projects.reports.new.save_PDF_to_inventory_modal.success_flash'
        )
      }, status: :ok
    else
      render json: { message: save_pdf_to_inventory_item.error_messages },
             status: :unprocessable_entity
    end
  rescue ReportActions::RepositoryPermissionError => error
    render json: { message: error },
           status: :forbidden
  rescue Exception => error
    render json: { message: error.message },
           status: :internal_server_error
  end

  # Modal for saving the existsing/new report
  def save_modal
    # Assume user is updating existing report
    @report = @project.reports.find_by_id(params[:id])
    @method = :put

    # Case when saving a new report
    if @report.blank?
      @report = Report.new
      @method = :post
      @url = project_reports_path(@project, format: :json)
    else
      @url = project_report_path(@project, @report, format: :json)
    end

    render_403 and return unless params.include? :contents

    @report_contents = params[:contents]

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'reports/new/modal/save.html.erb'
          )
        }
      end
    end
  end

  # Modal for adding contents into project element
  def project_contents_modal
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'reports/new/modal/project_contents.html.erb',
            locals: { project: @project }
          )
        }
      end
    end
  end

  # Experiment for adding contents into experiment element
  def experiment_contents_modal
    experiment = @project.experiments.find_by_id(params[:experiment_id])

    respond_to do |format|
      if experiment.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: 'reports/new/modal/experiment_contents.html.erb',
              locals: { project: @project, experiment: experiment }
            )
          }
        end
      end
    end
  end

  # Modal for adding contents into module element
  def module_contents_modal
    my_module = MyModule.find_by_id(params[:my_module_id])
    return render_403 unless my_module.experiment.project == @project

    respond_to do |format|
      if my_module.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: 'reports/new/modal/module_contents.html.erb',
              locals: { project: @project, my_module: my_module }
            )
          }
        end
      end
    end
  end

  # Modal for adding contents into step element
  def step_contents_modal
    step = Step.find_by_id(params[:step_id])
    return render_403 unless step.my_module.experiment.project == @project

    respond_to do |format|
      if step.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: 'reports/new/modal/step_contents.html.erb',
              locals: { project: @project, step: step }
            )
          }
        end
      end
    end
  end

  # Modal for adding contents into result element
  def result_contents_modal
    result = Result.find_by_id(params[:result_id])
    return render_403 unless result.experiment.project == @project

    respond_to do |format|
      if result.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: 'reports/new/modal/result_contents.html.erb',
              locals: { project: @project, result: result }
            )
          }
        end
      end
    end
  end

  def project_contents
    respond_to do |format|
      elements = generate_project_contents_json

      if elements_empty? elements
        format.json { render json: {}, status: :no_content }
      else
        format.json do
          render json: {
            status: :ok,
            elements: elements
          }
        end
      end
    end
  end

  def experiment_contents
    experiment = @project.experiments.find_by(id: params[:id])
    module_ids = (params[:modules].select { |_, p| p == '1' }).keys.collect(&:to_i)
    selected_modules = experiment.my_modules.where(id: module_ids)

    respond_to do |format|
      if experiment.blank?
        format.json { render json: {}, status: :not_found }
      elsif selected_modules.blank?
        format.json { render json: {}, status: :no_content }
      else
        elements = generate_experiment_contents_json(selected_modules)
      end

      if elements_empty? elements
        format.json { render json: {}, status: :no_content }
      else
        format.json do
          render json: {
            status: :ok,
            elements: elements
          }
        end
      end
    end
  end

  def module_contents
    my_module = MyModule.find_by_id(params[:id])
    return render_403 unless my_module.experiment.project == @project

    respond_to do |format|
      if my_module.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_module_contents_json(my_module)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json do
            render json: {
              status: :ok,
              elements: elements
            }
          end
        end
      end
    end
  end

  def step_contents
    step = Step.find_by_id(params[:id])
    return render_403 unless step.my_module.experiment.project == @project

    respond_to do |format|
      if step.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_step_contents_json(step)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json {
            render json: {
              status: :ok,
              elements: elements
            }
          }
        end
      end
    end
  end

  def result_contents
    result = Result.find_by_id(params[:id])
    return render_403 unless result.my_module.experiment.project == @project

    respond_to do |format|
      if result.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_result_contents_json(result)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json {
            render json: {
              status: :ok,
              elements: elements
            }
          }
        end
      end
    end
  end

  def visible_projects
    render json: { projects: @visible_projects }, status: :ok
  end

  def available_repositories
    render json: { results: @available_repositories }, status: :ok
  end

  private

  include StringUtility
  VisibleProject = Struct.new(:path, :name)
  AvailableRepository = Struct.new(:id, :name)

  def load_vars
    @report = current_team.reports.find_by(id: params[:id])
    render_404 unless @report
  end

  def load_vars_nested
    @project = current_team.projects.find_by(id: params[:project_id])
    render_404 unless @project
    render_403 unless can_read_project?(@project)
  end

  def check_manage_permissions
    render_403 unless can_manage_reports?(@project.team)
  end

  def load_visible_projects
    render_404 unless current_team
    projects = Project.visible_from_user_by_name(
      current_user, current_team, search_params[:q]
    ).limit(Constants::SEARCH_LIMIT).select(:id, :name)
    @visible_projects = projects.collect do |project|
      VisibleProject.new(new_project_reports_path(project),
                         ellipsize(project.name, 50, 40))
    end
  end

  def load_available_repositories
    @available_repositories = []
    repositories = Repository.accessible_by_teams(current_team)
                             .name_like(search_params[:q])
                             .limit(Constants::SEARCH_LIMIT)
                             .select(:id, :name, :team_id, :permission_level)
    repositories.each do |repository|
      next unless can_manage_repository_rows?(current_user, repository)

      @available_repositories.push(AvailableRepository.new(repository.id,
                                                           ellipsize(repository.name, 75, 50)))
    end
  end

  def report_params
    params.require(:report)
          .permit(:name, :description, :grouped_by, :report_contents)
  end

  def search_params
    params.permit(:q)
  end

  def save_PDF_params
    params.permit(:repository_id,
                  :respository_column_id,
                  :repository_item_id,
                  :html)
  end

  def log_activity(type_of, report = @report)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: report,
            team: report.team,
            project: report.project,
            message_items: { report: report.id })
  end
end
