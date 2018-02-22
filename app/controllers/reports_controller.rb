class ReportsController < ApplicationController
  include TeamsHelper
  include ReportActions
  # Ignore CSRF protection just for PDF generation (because it's
  # used via target='_blank')
  protect_from_forgery with: :exception, except: :generate

  before_action :load_vars, only: [
    :edit,
    :update
  ]
  before_action :load_vars_nested, only: [
    :index,
    :new,
    :create,
    :edit,
    :update,
    :generate,
    :destroy,
    :save_modal,
    :project_contents_modal,
    :experiment_contents_modal,
    :module_contents_modal,
    :step_contents_modal,
    :result_contents_modal,
    :project_contents,
    :module_contents,
    :step_contents,
    :result_contents
  ]

  before_action :check_view_permissions, only: :index
  before_action :check_manage_permissions, only: %i(
    new
    create
    edit
    update
    destroy
    generate
    save_modal
    project_contents_modal
    experiment_contents_modal
    module_contents_modal
    step_contents_modal
    result_contents_modal
    project_contents
    module_contents
    step_contents
    result_contents
  )

  layout 'fluid'

  # Index showing all reports of a single project
  def index
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
    @report.last_modified_by = current_user

    if continue && @report.save_with_contents(report_contents)
      # record an activity
      Activity.create(
        type_of: :create_report,
        project: @report.project,
        user: current_user,
        message: I18n.t(
          'activities.create_report',
          user: current_user.full_name,
          report: @report.name
        )
      )
      respond_to do |format|
        format.json do
          render json: { url: project_reports_path(@project) }, status: :ok
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
      # record an activity
      Activity.create(
        type_of: :edit_report,
        project: @report.project,
        user: current_user,
        message: I18n.t(
          'activities.edit_report',
          user: current_user.full_name,
          report: @report.name
        )
      )
      respond_to do |format|
        format.json do
          render json: { url: project_reports_path(@project) }, status: :ok
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
      next unless report.present?
      # record an activity
      Activity.create(
        type_of: :delete_report,
        project: report.project,
        user: current_user,
        message: I18n.t(
          'activities.delete_report',
          user: current_user.full_name,
          report: report.name
        )
      )
      report.destroy
    end

    redirect_to project_reports_path(@project)
  end

  # Generation action
  # Currently, only .PDF is supported
  def generate
    respond_to do |format|
      format.pdf do
        @html = params[:html]
        @html = '<h1>No content</h1>' if @html.blank?
        render pdf: 'report',
          header: { right: '[page] of [topage]' },
          template: 'reports/report.pdf.erb',
          disable_javascript: true
      end
    end
  end

  # Modal for saving the existsing/new report
  def save_modal
    # Assume user is updating existing report
    @report = Report.find_by_id(params[:id])
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
    experiment = Experiment.find_by_id(params[:experiment_id])

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
        format.json {
          render json: {
            status: :ok,
            elements: elements
          }
        }
      end
    end
  end

  def experiment_contents
    experiment = Experiment.find_by_id(params[:id])
    modules = (params[:modules].select { |_, p| p == "1" })
              .keys
              .collect(&:to_i)

    respond_to do |format|
      if experiment.blank?
        format.json { render json: {}, status: :not_found }
      elsif modules.blank?
        format.json { render json: {}, status: :no_content }
      else
        elements = generate_experiment_contents_json(experiment, modules)
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

  private

  def load_vars
    @report = Report.find_by_id(params[:id])
    render_404 unless @report
  end

  def load_vars_nested
    @project = Project.find_by_id(params[:project_id])
    render_404 unless @project
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_manage_permissions
    render_403 unless can_manage_reports?(@project)
  end

  def report_params
    params.require(:report)
          .permit(:name, :description, :grouped_by, :report_contents)
  end
end
