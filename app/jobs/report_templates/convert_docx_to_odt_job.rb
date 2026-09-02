# frozen_string_literal: true

module ReportTemplates
  class ConvertDocxToOdtJob < ApplicationJob
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

      report_template.generate_preview!
    end
  end
end
