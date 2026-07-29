# frozen_string_literal: true

module MyModules
  class GenerateReportJob < ApplicationJob
    def perform(report_template_id, my_module_id, user_id:, team_id:)
      report_template = ReportTemplate.find(report_template_id)
      my_module = MyModule.find(my_module_id)
      user = User.find(user_id)
      team = Team.find(team_id)

      my_module_report = MyModuleReport.new({ name: report_template.name })
      my_module_report.my_module = my_module

      MyModuleReports::GenerateReportService.new(my_module.protocol, report_template, team, user).call(my_module_report)
      my_module_report.save!

      PdfPreviewService.new(my_module_report.report, my_module_report.report).generate!
    ensure
      report_template&.update(generating_report: false)
    end
  end
end
