# frozen_string_literal: true

class ExperimentReportsController < ApplicationController
  before_action :load_experiment
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)
  before_action :load_analytical_report, only: %i(download destroy)

  def index
    @analytical_reports = @experiment.analytical_reports.where(generating_status: :done).order(:created_at)
  end

  def create
    analytical_report = AnalyticalReport.create!(
      name: create_params[:name],
      generating_status: :in_progress,
      reference: @experiment
    )

    Experiments::GenerateReportJob.perform_later(analytical_report.id, create_params[:task_ids], user_id: current_user.id)
  end

  def destroy
    @analytical_report.destroy!
    render body: nil, status: :ok
  end

  def download
    redirect_to rails_blob_path(analytical_report.report, disposition: 'attachment')
  end

  private

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
end
