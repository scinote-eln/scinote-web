# frozen_string_literal: true

class ExperimentReportsController < ApplicationController
  before_action :check_experiment_reporting_enabled
  before_action :load_experiment
  before_action :check_view_permissions, except: %i(create destroy my_modules)
  before_action :check_manage_permissions, only: %i(create destroy my_modules)
  before_action :load_analytical_report, only: %i(download destroy preview)

  def index
    @analytical_reports = @experiment.analytical_reports.where(generating_status: :done).order(created_at: :desc)
  end

  def create
    analytical_report = AnalyticalReport.create!(
      name: create_params[:name],
      generating_status: :in_progress,
      reference: @experiment,
      created_by: current_user
    )

    Experiments::GenerateReportJob.perform_later(analytical_report.id, create_params[:task_ids])
  end

  def destroy
    ActiveRecord::Base.transaction do
      log_activity(:experiment_analytical_report_deleted)
      @analytical_report.destroy!
      render body: nil, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def download
    redirect_to rails_blob_path(@analytical_report.report, disposition: 'attachment')
  end

  def preview
    render json: { html: render_to_string(
      partial: 'analytical_reports/preview',
      locals: {
        report: @analytical_report,
        download_url: download_experiment_experiment_report_path(@experiment.id, @analytical_report)
      },
      formats: :html
    ) }
  end

  def my_modules
    @my_modules = @experiment.my_modules.readable_by_user(current_user).joins(:analytical_reports).distinct
  end

  private

  def check_experiment_reporting_enabled
    render_403 unless AnalyticalReport.experiment_reporting_enabled?
  end

  def load_experiment
    @experiment = Experiment.find_by(id: params[:experiment_id])

    render_404 unless @experiment

    current_team_switch(@experiment.project.team) if current_team != @experiment.project.team
  end

  def create_params
    params.permit(:name, task_ids: [])
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@experiment)
  end

  def check_manage_permissions
    render_403 unless can_manage_experiment?(@experiment)
  end

  def load_analytical_report
    @analytical_report = @experiment.analytical_reports.find_by(id: params[:id])

    render_404 unless @analytical_report
  end

  def log_activity(type_of)
    experiment = @analytical_report.reference
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: @analytical_report.created_by,
            team: experiment.team,
            project: experiment.project,
            subject: experiment,
            message_items: { analytical_report: @analytical_report.id,
                             experiment: experiment.id })
  end
end
