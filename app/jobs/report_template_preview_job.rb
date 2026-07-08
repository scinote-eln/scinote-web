# frozen_string_literal: true

class ReportTemplatePreviewJob < ApplicationJob
  def perform(report_template_id)
    report_template = ReportTemplate.find(report_template_id)
    PdfPreviewService.new(report_template.odt_template_file, report_template.odt_template_file_preview).generate!
  end
end
