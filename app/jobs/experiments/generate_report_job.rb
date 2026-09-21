# frozen_string_literal: true

module Experiments
  class GenerateReportJob < ApplicationJob
    def perform(analytical_report_id)
      analytical_report = AnalyticalReport.find(analytical_report_id)

      ExperimentReports::GenerateReportService.new(analytical_report.reference, analytical_report, analytical_report.created_by).call
      analytical_report&.update(generating_status: :done)
      log_activity(analytical_report)
    rescue StandardError => e
      analytical_report&.destroy
      raise e
    end

    private

    def log_activity(analytical_report)
      experiment = analytical_report.reference
      Activities::CreateActivityService
        .call(activity_type: :experiment_analytical_report_generated,
              owner: analytical_report.created_by,
              team: experiment.team,
              project: experiment.project,
              subject: experiment,
              message_items: { analytical_report: analytical_report.id,
                               experiment: experiment.id })
    end
  end
end
