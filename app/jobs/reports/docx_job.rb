# frozen_string_literal: true

module Reports
  class DocxJob < ApplicationJob
    include InputSanitizeHelper

    queue_as :reports

    discard_on StandardError do |job, error|
      report = Report.find_by(id: job.arguments.first)
      ActiveRecord::Base.no_touching do
        report&.update(docx_file_processing: false)
      end
      Rails.logger.error("Couldn't generate DOCX for Report with id: #{job.arguments.first}. Error:\n #{error}")
    end

    def perform(report, user, team, root_url)
      file = Tempfile.new(['report', '.docx'])
      begin
        docx = Caracal::Document.new(file.path)
        Reports::Docx.new(report, docx, user: user, team: team, scinote_url: root_url).draw
        docx.save
        report.docx_file.attach(io: file, filename: 'report.docx')
        report.update!(docx_file_processing: false)
        report_path = Rails.application.routes.url_helpers.reports_path
        notification = Notification.create(
          type_of: :deliver,
          title: I18n.t('projects.reports.index.generation.completed_docx_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{sanitize_input(report.name)}</a>",
                          team_name: sanitize_input(report.team.name))
        )
        notification.create_user_notification(user)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
