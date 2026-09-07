# frozen_string_literal: true

class MyModuleReportsController < ApplicationController
  include ApplicationHelper
  include Breadcrumbs
  include TeamsHelper

  before_action :load_my_module
  before_action :check_analytical_reporting
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)
  before_action :load_analytical_report, only: %i(download destroy preview)
  before_action :load_protocol_report_template, only: :create
  before_action :set_breadcrumbs_items, only: %i(index)
  before_action :set_navigator, only: %i(index)
  before_action :set_inline_name_editing, only: %i(index)

  def index
    respond_to do |format|
      format.json do
        @analytical_reports = @my_module.analytical_reports.where(generating_status: :done).order(:created_at)
      end

      format.html do
        render(:index, formats: :html)
      end
    end
  end

  def create
    analytical_report = AnalyticalReport.create!(
      name: @report_template.name,
      generating_status: :in_progress,
      reference: @my_module,
      report_template_id: @report_template.id
    )

    MyModules::GenerateReportJob.perform_later(analytical_report.id, create_params, user_id: current_user.id, team_id: current_team.id)
  end

  def report_templates
    @in_progress_template_ids = @my_module.analytical_reports
                                          .where(generating_status: :in_progress)
                                          .distinct
                                          .pluck(:report_template_id)
                                          .to_set
    @report_templates = @my_module.protocol.report_templates.order(:created_at)
  end

  def pdfs
    step_assets = @my_module.assets_in_steps.pdfs.order('steps.position ASC, active_storage_blobs.filename ASC')

    result_assets = @my_module.assets_in_results.pdfs.order('results.created_at DESC, active_storage_blobs.filename ASC')
    @assets = (step_assets + result_assets)
  end

  def destroy
    @analytical_report.destroy!
    render body: nil, status: :ok
  end

  def download
    redirect_to rails_blob_path(@analytical_report.report, disposition: 'attachment')
  end

  def preview
    render json: { html: render_to_string(
      partial: 'my_module_reports/preview',
      locals: {
        my_module_id: @my_module.id,
        report: @analytical_report
      },
      formats: :html
    ) }
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])

    render_404 unless @my_module

    current_team_switch(@my_module.experiment.project.team) if current_team != @my_module.experiment.project.team
  end

  def check_analytical_reporting
    render_403 unless ReportTemplate.analytical_reporting_enabled?
  end

  def create_params
    params.permit(:header, :footer, :add_numarization, :add_blank_page, asset_ids: [])
  end

  def load_analytical_report
    @analytical_report = @my_module.analytical_reports.find_by(id: params[:id])

    render_404 unless @analytical_report
  end

  def load_protocol_report_template
    @report_template = @my_module.protocol.report_templates.find_by(id: params[:report_template_id])

    render_404 unless @report_template
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_manage_my_module_reports?(@my_module)
  end

  def set_navigator
    @navigator = {
      url: tree_navigator_my_module_path(@my_module),
      archived: @my_module.archived_branch?,
      id: @my_module.code
    }
  end

  def set_inline_name_editing
    return unless can_manage_my_module?(@my_module)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'my_module',
      item_id: @my_module.id,
      field_to_udpate: 'name',
      path_to_update: my_module_path(@my_module)
    }
  end
end
