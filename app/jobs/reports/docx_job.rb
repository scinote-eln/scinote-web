# frozen_string_literal: true

module Reports
  class DocxJob < ApplicationJob
    extend InputSanitizeHelper
    include InputSanitizeHelper
    include FailedDeliveryNotifiableJob

    queue_as :reports

    def perform(report_id, user_id:, root_url:)
      report = Report.find(report_id)
      user = User.find(user_id)
      file = Tempfile.new(['report', '.docx'])
      begin
        I18n.backend.date_format = user.settings[:date_format]
        docx = Caracal::Document.new(file.path)
        Reports::Docx.new(report, docx, user: user, scinote_url: root_url).draw
        docx.save
        report.docx_file.attach(io: file, filename: 'report.docx')
        report.docx_ready!
        report_path = Rails.application.routes.url_helpers
                           .reports_path(team: report.team.id, preview_report_id: report.id, preview_type: :docx)

        DeliveryNotification.with(
          title: I18n.t('projects.reports.index.generation.completed_docx_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
                          team_name: escape_input(report.team.name))
        ).deliver(user)

        Reports::DocxPreviewJob.perform_now(report.id)
      ensure
        I18n.backend.date_format = nil
        file.close
        file.unlink
      end
    rescue StandardError => e
      raise e if report.blank?

      ActiveRecord::Base.no_touching do
        report.docx_error!
      end
      Rails.logger.error("Couldn't generate DOCX for Report with id: #{report.id}. Error:\n #{e.message}")
      raise e
    end

    private

    # Overrides method from FailedDeliveryNotifiableJob concern
    def failed_notification_title
      I18n.t('projects.reports.index.generation.error_docx_notification_title')
    end

    # Overrides method from FailedDeliveryNotifiableJob concern
    def failed_notification_message
      report = Report.find_by(id: arguments.first)
      return '' if report.blank?

      report_path =
        if report.docx_file.attached?
          Rails.application.routes.url_helpers
               .reports_path(team: report.team.id, preview_report_id: report.id, preview_type: :docx)
        else
          Rails.application.routes.url_helpers.reports_path(team: report.team.id)
        end

      I18n.t('projects.reports.index.generation.error_notification_message',
             report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
             team_name: escape_input(report.team.name))
    end
  end
end
