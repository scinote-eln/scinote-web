# frozen_string_literal: true

class MyModuleReportsController < ApplicationController
  include ApplicationHelper
  include Breadcrumbs
  include TeamsHelper

  before_action :load_my_module
  before_action :check_analytical_reporting, only: :create
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)
  before_action :load_my_module_report, only: %i(download destroy preview)
  before_action :load_protocol_report_template, only: :create
  before_action :set_breadcrumbs_items, only: %i(index)
  before_action :set_navigator, only: %i(index)
  before_action :set_inline_name_editing, only: %i(index)

  def index
    respond_to do |format|
      format.json do
        render json: {
          templates: @my_module.protocol.report_templates.map do |report_template|
            {
              id: report_template.id,
              name: report_template.name,
              preview: preview_protocol_protocol_report_template_path(@my_module.protocol, report_template)
            }
          end
        }
      end

      format.html do
        render(:index, formats: :html)
      end
    end
  end

  def create
    my_module_report = MyModuleReport.new({ name: @report_template.name })
    my_module_report.my_module = @my_module

    MyModuleReports::GenerateReportService.new(@my_module.protocol, @report_template, current_team, current_user).call(my_module_report)
    my_module_report.save!
    PdfPreviewService.new(my_module_report.report, my_module_report.report).generate!
  end

  def generated_reports
    render json: {
      reports: @my_module.my_module_reports.map do |my_module_report|
        {
          id: my_module_report.id,
          name: my_module_report.name,
          created_at: I18n.l(my_module_report.created_at, format: :full_date),
          preview: preview_my_module_my_module_report_path(@my_module, my_module_report)
        }
      end
    }
  end

  def destroy
    @my_module_report.destroy!
    render body: nil, status: :ok
  end

  def download
    redirect_to rails_blob_path(@my_module_report.report, disposition: 'attachment')
  end

  def preview
    render json: { html: render_to_string(
      partial: 'my_module_reports/preview',
      locals: {
        my_module_id: @my_module.id,
        report: @my_module_report
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

  def load_my_module_report
    @my_module_report = @my_module.my_module_reports.find_by(id: params[:id])

    render_404 unless @my_module_report
  end

  def load_protocol_report_template
    @report_template = @my_module.protocol.report_templates.find_by(id: params[:report_template_id])

    render_404 unless @report_template
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_manage_my_module?(@my_module)
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
