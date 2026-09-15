# frozen_string_literal: true

module ReportTemplates
  class ReportTemplatePreviewJob < ApplicationJob
    discard_on StandardError do |job, error|
      report_template = ReportTemplate.find_by(id: job.arguments.first)

      if report_template
        blob = report_template.odt_template_file.blob
        blob.metadata['preview_failed'] = true
        blob.update_column(:metadata, blob.metadata) # rubocop:disable Rails/SkipsModelValidations

        ReportTemplatePreviewChannel.broadcast_to(report_template, status: report_template.preview_status)
      end

      Rails.logger.error "Couldn't generate PDF preview for ReportTemplate with id: #{job.arguments.first}. Error:\n#{error}"
    end

    def perform(report_template_id)
      report_template = ReportTemplate.find(report_template_id)
      PdfPreviewService.new(report_template.odt_template_file, report_template.odt_template_file_preview).generate!

      ReportTemplatePreviewChannel.broadcast_to(report_template, status: report_template.preview_status)
    end
  end
end
