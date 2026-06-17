# frozen_string_literal: true

module Reports
  class DocxTemplateJob < DocxJob
    def perform(report_id, user_id:, root_url:)
      report = Report.find(report_id)
      user = User.find(user_id)
      report_odt_file = Tempfile.new(['report', '.odt'])
      report_docx_file = nil
      begin
        I18n.backend.date_format = user.settings[:date_format]

        odt_report = nil

        report.odt_template_file.open do |odt_template_file|
          odt_report = ODFReport::Report.new(
              odt_template_file.path
            ) do |r|
              r.add_field(:id, report.id.to_s)
              r.add_field(:created_by, report.created_by)
              r.add_field(:created_at, report.created_at.strftime("%d/%m/%Y - %H:%M"))
              r.add_text :notes, '<h1>Notes</h1>'
              r.add_checklist(:form, [
              { text: "Design approved", checked: true },
              { text: "Code reviewed",   checked: false },
              ["Array form", true],
              "Bare string (unchecked)",
            ])
            end

          odt_report.generate(report_odt_file.path)
        end

        report_docx_file = Reports::ConvertToDocxService.convert(report_odt_file)
        report.docx_file.attach(io: report_docx_file, filename: 'report.docx')

        DeliveryNotification.send_notifications(
          {
            title: I18n.t('projects.reports.index.generation.completed_docx_notification_title'),
            subject_id: report_id,
            subject_class: 'Report',
            subject_name: report.name,
            report_type: 'docx',
            user_id: user.id
          }
        )

        Reports::DocxPreviewJob.perform_now(report.id)
        report.docx_ready!
      ensure
        I18n.backend.date_format = nil
        report_odt_file.close
        report_odt_file.unlink
        File.delete(report_docx_file.path) if report_docx_file && File.file?(report_docx_file.path)
      end
    rescue StandardError => e
      raise e if report.blank?

      ActiveRecord::Base.no_touching do
        report.docx_error!
      end
      Rails.logger.error("Couldn't generate DOCX for Report with id: #{report.id}. Error:\n #{e.message}")
      raise e
    end
  end
end
