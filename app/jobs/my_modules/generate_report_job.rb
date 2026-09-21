# frozen_string_literal: true

module MyModules
  class GenerateReportJob < ApplicationJob
    def perform(analytical_report_id, team_id:)
      analytical_report = AnalyticalReport.find(analytical_report_id)
      asset_ids = analytical_report.params["asset_ids"]
      header_text = analytical_report.params["header"]
      footer_text = analytical_report.params["footer"]
      add_numarization = analytical_report.params["add_numarization"]
      add_blank_page = analytical_report.params["add_blank_page"]

      user = analytical_report.created_by
      team = Team.find(team_id)

      I18n.backend.date_format = user.settings[:date_format]

      MyModuleReports::GenerateReportService.new(analytical_report.reference.protocol, analytical_report.report_template, team, user).call(analytical_report)

      PdfPreviewService.new(analytical_report.report, analytical_report.report).generate!
      if asset_ids.present?
        MyModuleReports::MergePdfsWithWatermarkService.new(user, analytical_report, asset_ids, header_text, footer_text, add_numarization, add_blank_page).generate!
      end
      analytical_report&.update(generating_status: :done)

      log_activity(analytical_report)
    rescue StandardError => e
      analytical_report&.destroy
      raise e
    ensure
      I18n.backend.date_format = nil
    end

    private

    def log_activity(analytical_report)
      my_module = analytical_report.reference
      Activities::CreateActivityService
        .call(activity_type: :task_analytical_report_generated,
              owner: analytical_report.created_by,
              team: my_module.team,
              project: my_module.project,
              subject: my_module,
              message_items: { analytical_report: analytical_report.id,
                               report_template: analytical_report.report_template.id,
                               my_module: my_module.id })
    end
  end
end
