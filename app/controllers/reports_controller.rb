class ReportsController < ApplicationController
  include TeamsHelper
  include ReportActions
  include ReportsHelper
  include StringUtility

  before_action :load_vars, only: %i(edit update document_preview generate_pdf generate_docx status
                                     save_pdf_to_inventory_modal save_pdf_to_inventory_item)
  before_action :load_vars_nested, only: %i(create edit update generate_pdf
                                            generate_docx new_template_values project_contents)
  before_action :load_wizard_vars, only: %i(new edit)
  before_action :load_available_repositories, only: %i(index save_pdf_to_inventory_modal available_repositories)
  before_action :check_project_read_permissions, only: %i(create edit update generate_pdf
                                                          generate_docx new_template_values project_contents)
  before_action :check_read_permissions, except: %i(index new create edit update destroy actions_toolbar generate_pdf
                                                    generate_docx new_template_values project_contents
                                                    available_repositories)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit update generate_pdf generate_docx)
  before_action :switch_team_with_param, only: :index
  after_action :generate_pdf_report, only: %i(create update generate_pdf)

  # Index showing all reports of a single project
  def index
    respond_to do |format|
      format.json do
        reports = Lists::ReportsService.new(Report.viewable_by_user(current_user, current_team), params).call
        render json: reports, each_serializer: Lists::ReportSerializer,
               user: current_user, meta: pagination_dict(reports)
      end
      format.html do
        render 'index'
      end
    end
  end

  # Report grouped by modules
  def new
    @templates = Extends::REPORT_TEMPLATES
    @report = current_team.reports.new
  end

  def new_template_values
    if Extends::REPORT_TEMPLATES.key?(params[:template]&.to_sym)
      template = params[:template]
    else
      return render_404
    end

    report = current_team.reports.where(project: @project).find_by(id: params[:report_id])
    if report.present?
      return render_403 unless can_manage_report?(report)
    else
      return render_403 unless can_create_reports?(current_team)

      report = current_team.reports.new(project: @project)
    end

    if lookup_context.any_templates?("reports/templates/#{template}/edit")
      render json: {
        html: render_to_string(
          template: "reports/templates/#{template}/edit",
          layout: 'reports/template_values_editor',
          locals: { report: report },
          formats: :html
        )
      }
    else
      render json: {
        html: render_to_string(partial: 'reports/wizard/no_template_values',
                               formats: :html)
      }
    end
  end

  # Creating new report from the _save modal of the new page
  def create
    @report = Report.new(report_params)
    @report.project = @project
    @report.user = current_user
    @report.team = current_team
    @report.settings = report_params[:settings]
    @report.last_modified_by = current_user

    ReportActions::ReportContent.new(
      @report,
      params[:project_content],
      params[:template_values],
      current_user
    ).save_with_content

    if @report.errors.blank?
      log_activity(:create_report)
      flash[:success] = t('projects.reports.index.generation.accepted_message')

      redirect_to reports_path
    else
      render json: @report.errors.full_messages, status: :unprocessable_entity
    end
  end

  def edit
    @edit = true
    @active_template = @report.settings[:template]
    @report.settings = Report::DEFAULT_SETTINGS if @report.settings.blank?

    @project_contents = {
      experiments: @report.report_elements.order(:position).experiment.pluck(:experiment_id),
      my_modules: @report.report_elements.order(:position).my_module.pluck(:my_module_id),
      repositories: @report.settings.dig(:task, :repositories) ||
                    @report.report_elements.my_module_repository.distinct(:repository_id).pluck(:repository_id)
    }
    render :new
  end

  # Updating existing report from the _save modal of the new page
  def update
    @report.last_modified_by = current_user
    @report.assign_attributes(
      report_params.merge(project_id: @project.id)
    )

    ReportActions::ReportContent.new(
      @report,
      params[:project_content],
      params[:template_values],
      current_user
    ).save_with_content

    if @report.errors.blank?
      log_activity(:edit_report)
      flash[:success] = t('projects.reports.index.generation.accepted_message')

      redirect_to reports_path
    else
      render json: @report.errors.full_messages, status: :unprocessable_entity
    end
  end

  # Destroy multiple entries action
  def destroy
    begin
      report_ids = params[:report_ids]
    rescue
      render_404
    end

    report_ids.each do |report_id|
      report = current_team.reports.find_by(id: report_id)
      next unless report.present? && can_manage_report?(report)

      # record an activity
      log_activity(:delete_report, report)
      report.destroy
    end

    render json: { message: I18n.t('projects.reports.index.modal_delete.success') }
  end

  def status
    render json: @report, serializer: Lists::ReportSerializer
  end

  # Generation actions
  def generate_pdf
    render json: {
      message: I18n.t('projects.reports.index.generation.accepted_message')
    }
  end

  def generate_docx
    @report.docx_processing!
    log_activity(:generate_docx_report)

    ensure_report_template!
    Reports::DocxJob.perform_later(@report.id, user_id: current_user.id, root_url: root_url)
    render json: {
      message: I18n.t('projects.reports.index.generation.accepted_message')
    }
  end

  def save_pdf_to_inventory_modal
    render json: {
      html: render_to_string(partial: 'reports/save_PDF_to_inventory_modal', formats: :html)
    }
  end

  def save_pdf_to_inventory_item
    return render_404 unless @report.pdf_file.attached?

    save_pdf_to_inventory_item = ReportActions::SavePdfToInventoryItem.new(
      @report, current_user, current_team, save_pdf_params
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
  rescue ReportActions::RepositoryPermissionError => e
    render json: { message: e.message }, status: :forbidden
  rescue StandardError => e
    render json: { message: e.message }, status: :internal_server_error
  end

  # Modal for adding contents into module element
  def module_contents_modal
    my_module = MyModule.find_by_id(params[:my_module_id])
    return render_403 unless my_module.experiment.project == @project

    if my_module.blank?
      render json: {}, status: :not_found
    else
      render json: {
        html: render_to_string(
          partial: 'reports/new/modal/module_contents',
          locals: { project: @project, my_module: my_module },
          formats: :html
        )
      }
    end
  end

  # Modal for adding contents into step element
  def step_contents_modal
    step = Step.find_by_id(params[:step_id])
    return render_403 unless step.my_module.experiment.project == @project

    if step.blank?
      render json: {}, status: :not_found
    else
      render json: {
        html: render_to_string(
          partial: 'reports/new/modal/step_contents',
          locals: { project: @project, step: step },
          formats: :html
        )
      }
    end
  end

  # Modal for adding contents into result element
  def result_contents_modal
    result = Result.find_by_id(params[:result_id])
    return render_403 unless result.experiment.project == @project

    if result.blank?
      render json: {}, status: :not_found
    else
      render json: {
        html: render_to_string(
          partial: 'reports/new/modal/result_contents',
          locals: { project: @project, result: result },
          formats: :html
        )
      }
    end
  end

  def project_contents
    render json: {
      html: render_to_string(
        partial: 'reports/wizard/project_contents',
        locals: { project: @project, report: nil },
        formats: :html
      )
    }
  end

  def available_repositories
    render json: { data: @available_repositories.map { |r| [r.id, r.name] } }
  end

  def document_preview
    render json: { html: render_to_string(
      partial: 'reports/content_document_preview',
      locals: {
        report: @report,
        report_type: params[:report_type]
      },
      formats: :html
    ) }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ReportsService.new(
          current_user,
          report_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  private

  AvailableRepository = Struct.new(:id, :name)

  def load_vars
    @report = current_team.reports.find_by(id: params[:id])
    render_404 unless @report
  end

  def load_vars_nested
    @project = current_team.projects.find_by(id: params[:project_id])
    render_404 unless @project
  end

  def load_wizard_vars
    @templates = Extends::REPORT_TEMPLATES
    live_repositories = Repository.accessible_by_teams(current_team).sort_by { |r| r.name.downcase }
    snapshots_of_deleted = RepositorySnapshot.left_outer_joins(:original_repository)
                                             .where(team: current_team)
                                             .where.not(original_repository: live_repositories)
                                             .select('DISTINCT ON ("repositories"."parent_id") "repositories".*')
                                             .sort_by { |r| r.name.downcase }
    @repositories = live_repositories + snapshots_of_deleted
    @visible_projects = current_team.projects
                                    .active
                                    .joins(experiments: :my_modules)
                                    .with_granted_permissions(current_user, ProjectPermissions::READ)
                                    .merge(Experiment.active)
                                    .merge(MyModule.active)
                                    .group(:id)
                                    .select(:id, :name)
  end

  def check_project_read_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_read_permissions
    render_403 unless can_read_report?(@report)
  end

  def check_create_permissions
    render_403 unless can_create_reports?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_report?(@report)
  end

  def load_available_repositories
    @available_repositories = []
    repositories = Repository.active
                             .accessible_by_teams(current_team)
                             .name_like(search_params[:query])
                             .limit(Constants::SEARCH_LIMIT)
    repositories.each do |repository|
      next unless can_manage_repository_rows?(current_user, repository)

      @available_repositories.push(AvailableRepository.new(repository.id,
                                                           ellipsize(repository.name, 75, 50)))
    end
  end

  def report_params
    params.require(:report)
          .permit(:name, :description, :grouped_by, :report_contents, settings: {})
  end

  def search_params
    params.permit(:query)
  end

  def save_pdf_params
    params.permit(:repository_id, :repository_column_id, :repository_item_id)
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

  def generate_pdf_report
    return unless @report.persisted?

    @report.pdf_processing!
    log_activity(:generate_pdf_report)

    ensure_report_template!
    Reports::PdfJob.perform_later(@report.id, user_id: current_user.id)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error e.message
  end

  def ensure_report_template!
    return if @report.settings['template'].present?

    @report.settings['template'] = 'scinote_template'
    @report.save
  end
end
