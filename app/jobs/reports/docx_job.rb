# frozen_string_literal: true

module Reports
  class DocxJob < ApplicationJob
    extend InputSanitizeHelper
    include InputSanitizeHelper

    queue_as :reports

    discard_on StandardError do |job, error|
      report = Report.find_by(id: job.arguments.first)
      next unless report

      ActiveRecord::Base.no_touching do
        report.docx_error!
      end
      report_path =
        if report.docx_file.attached?
          Rails.application.routes.url_helpers
               .reports_path(team: report.team.id, preview_report_id: report.id, preview_type: :docx)
        else
          Rails.application.routes.url_helpers.reports_path(team: report.team.id)
        end
      user = User.find(job.arguments.second)
      notification = Notification.create(
        type_of: :deliver_error,
        title: I18n.t('projects.reports.index.generation.error_docx_notification_title'),
        message: I18n.t('projects.reports.index.generation.error_notification_message',
                        report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
                        team_name: escape_input(report.team.name))
      )
      notification.create_user_notification(user)
      Rails.logger.error("Couldn't generate DOCX for Report with id: #{report.id}. Error:\n #{error}")
    end

    def perform(report_id, user_id, root_url)
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
        notification = Notification.create(
          type_of: :deliver,
          title: I18n.t('projects.reports.index.generation.completed_docx_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
                          team_name: escape_input(report.team.name))
        )

        Reports::DocxPreviewJob.perform_now(report.id)
        notification.create_user_notification(user)
      ensure
        I18n.backend.date_format = nil
        file.close
        file.unlink
      end
    end
  end
end
