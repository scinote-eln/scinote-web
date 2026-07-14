# frozen_string_literal: true

module ReportTemplates
  class ConvertOdtToDocxJob < ApplicationJob
    def perform(report_template_id)
      report_template = ReportTemplate.find(report_template_id)
      blob = report_template.odt_template_file.blob

      blob.open do |file|
        odt_file = Reports::ConvertToDocxService.convert(file)

        report_template.docx_template_file.attach(
          io: odt_file,
          filename: "#{blob.filename.base}.docx"
        )
      end
    end
  end
end
