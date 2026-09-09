# frozen_string_literal: true

module MyModules
  class GenerateReportJob < ApplicationJob
    def perform(analytical_report_id, params, team_id:)
      asset_ids = params[:asset_ids]
      header_text = params[:header]
      footer_text = params[:footer]
      add_numarization = params[:add_numarization]
      add_blank_page = params[:add_blank_page]

      analytical_report = AnalyticalReport.find(analytical_report_id)
      user = analytical_report.created_by
      team = Team.find(team_id)

      I18n.backend.date_format = user.settings[:date_format]

      MyModuleReports::GenerateReportService.new(analytical_report.reference.protocol, analytical_report.report_template, team, user).call(analytical_report)

      PdfPreviewService.new(analytical_report.report, analytical_report.report).generate!
      if asset_ids.present?
        MyModuleReports::MergePdfsWithWatermarkService.new(user, analytical_report, asset_ids, header_text, footer_text, add_numarization, add_blank_page).generate!
      end
      analytical_report&.update(generating_status: :done)
    rescue StandardError => e
      analytical_report&.destroy
      raise e
    ensure
      I18n.backend.date_format = nil
    end
  end
end
