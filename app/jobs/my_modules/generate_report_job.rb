# frozen_string_literal: true

module MyModules
  class GenerateReportJob < ApplicationJob
    def perform(report_template_id, my_module_id, params, user_id:, team_id:)
      asset_ids = params[:asset_ids]
      header_text = params[:header]
      footer_text = params[:footer]
      add_numarization = params[:add_numarization]
      add_blank_page = params[:add_blank_page]

      report_template = ReportTemplate.find(report_template_id)
      my_module = MyModule.find(my_module_id)
      user = User.find(user_id)
      team = Team.find(team_id)

      I18n.backend.date_format = user.settings[:date_format]

      my_module_report = MyModuleReport.new({ name: report_template.name })
      my_module_report.my_module = my_module

      MyModuleReports::GenerateReportService.new(my_module.protocol, report_template, team, user).call(my_module_report)
      my_module_report.save!

      PdfPreviewService.new(my_module_report.report, my_module_report.report).generate!
      if asset_ids.present?
        MyModuleReports::MergePdfsWithWatermarkService.new(user, my_module_report, asset_ids, header_text, footer_text, add_numarization, add_blank_page).generate!
      end
    ensure
      I18n.backend.date_format = nil
      report_template&.update(generating_report: false)
    end
  end
end
