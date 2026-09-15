# frozen_string_literal: true

module ReportTemplates
  class ReportTemplatePreviewJob < ApplicationJob
    def perform(report_template_id)
      report_template = ReportTemplate.find(report_template_id)
      PdfPreviewService.new(report_template.odt_template_file, report_template.odt_template_file_preview).generate! if report_template.odt_template_file.attached?
      PdfPreviewService.new(report_template.docx_template_file, report_template.docx_template_file_preview).generate! if report_template.docx_template_file.attached?
    end
  end
end
