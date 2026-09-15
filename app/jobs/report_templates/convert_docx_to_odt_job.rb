# frozen_string_literal: true

module ReportTemplates
  class ConvertDocxToOdtJob < ApplicationJob
    discard_on StandardError do |job, error|
      report_template = ReportTemplate.find_by(id: job.arguments.first)

      if report_template
        blob = report_template.docx_template_file.blob
        blob.metadata['preview_failed'] = true
        blob.update_column(:metadata, blob.metadata) # rubocop:disable Rails/SkipsModelValidations

        ReportTemplatePreviewChannel.broadcast_to(report_template, status: report_template.preview_status)
      end

      Rails.logger.error "Couldn't convert docx to odt for ReportTemplate with id: #{job.arguments.first}. Error:\n#{error}"
    end

    def perform(report_template_id)
      report_template = ReportTemplate.find(report_template_id)
      blob = report_template.docx_template_file.blob

      blob.open do |file|
        odt_file = Reports::ConvertFileFormatService.convert(file, 'odt')

        report_template.odt_template_file.attach(
          io: odt_file,
          filename: "#{blob.filename.base}.odt",
          content_type: 'application/vnd.oasis.opendocument.text'
        )
      end

      ReportTemplatePreviewChannel.broadcast_to(report_template, status: report_template.preview_status)

      report_template.generate_preview!
    end
  end
end
