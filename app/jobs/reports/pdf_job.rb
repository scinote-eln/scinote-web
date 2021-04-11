# frozen_string_literal: true

module Reports
  class PdfJob < ApplicationJob
    include InputSanitizeHelper
    include ReportsHelper

    queue_as :reports

    def perform(report, template, user)
      file = Tempfile.new(['report', '.pdf'], binmode: true)
      begin
        template_name = Extends::REPORT_TEMPLATES[template.to_sym]

        raise StandardError if template_name.blank?

        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
        proxy.set_user(user, scope: :user, store: false)
        renderer = ApplicationController.renderer.new(warden: proxy)

        file << renderer.render(
          pdf: 'report', header: { html: { template: "reports/templates/#{template_name}/header",
                                           locals: { report: report },
                                           layout: 'reports/footer_header.html.erb' } },
                         cover: renderer.render_to_string("reports/templates/#{template_name}/cover.html.erb",
                                                          layout: false,
                                                          locals: { report: report }),
                         footer: { html: { template: "reports/templates/#{template_name}/footer",
                                           locals: { report: report },
                                           layout: 'reports/footer_header.html.erb' } },
                         locals: { report: report },
                         disable_javascript: false,
                         template: 'reports/report.pdf.erb'
        )

        file.rewind
        report.pdf_file.attach(io: file, filename: 'report.pdf')
        report.update!(pdf_file_processing: false)

        report_path = Rails.application.routes.url_helpers.reports_path
        notification = Notification.create(
          type_of: :deliver,
          title: I18n.t('projects.reports.index.generation.completed_notification_title'),
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
