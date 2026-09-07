# frozen_string_literal: true

module Experiments
  class GenerateReportJob < ApplicationJob
    def perform(analytical_report_id, my_module_ids, user_id:)
      analytical_report = AnalyticalReport.find(analytical_report_id)
      user = User.find(user_id)

      ExperimentReports::GenerateReportService.new(analytical_report.reference, analytical_report, user).call(my_module_ids)
      analytical_report&.update(generating_status: :done)
    rescue StandardError => e
      # analytical_report&.destroy
      raise e
    end
  end
end
