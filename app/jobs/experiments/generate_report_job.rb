# frozen_string_literal: true

module Experiments
  class GenerateReportJob < ApplicationJob
    def perform(analytical_report_id, my_module_ids)
      analytical_report = AnalyticalReport.find(analytical_report_id)

      ExperimentReports::GenerateReportService.new(analytical_report.reference, analytical_report, analytical_report.created_by).call(my_module_ids)
      analytical_report&.update(generating_status: :done)
    rescue StandardError => e
      analytical_report&.destroy
      raise e
    end
  end
end
