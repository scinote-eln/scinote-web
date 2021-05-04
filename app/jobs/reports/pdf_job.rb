# frozen_string_literal: true

module Reports
  class PdfJob < ApplicationJob
    include InputSanitizeHelper
    include ReportsHelper

    queue_as :reports

    discard_on StandardError do |job, error|
      report = Report.find_by(id: job.arguments.first)
      ActiveRecord::Base.no_touching do
        report&.update(pdf_file_processing: false)
      end
      Rails.logger.error("Couldn't generate PDF for Report with id: #{job.arguments.first}. Error:\n #{error}")
    end

    PREVIEW_EXTENSIONS = %w(docx pdf).freeze

    def perform(report, user)
      file = Tempfile.new(['report', '.pdf'], binmode: true)
      begin
        template_name = Extends::REPORT_TEMPLATES[report.settings[:template]&.to_sym]

        raise StandardError, 'Report template not found!' if template_name.blank?

        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
        proxy.set_user(user, scope: :user, store: false)
        renderer = ApplicationController.renderer.new(warden: proxy)

        file << renderer.render(
          pdf: 'report', header: { html: { template: "reports/templates/#{template_name}/header",
                                           locals: { report: report },
                                           layout: 'reports/footer_header.html.erb' } },
                         footer: { html: { template: "reports/templates/#{template_name}/footer",
                                           locals: { report: report },
                                           layout: 'reports/footer_header.html.erb' } },
                         assigns: { settings: report.settings },
                         locals: { report: report },
                         disable_javascript: false,
                         template: 'reports/report.pdf.erb'
        )

        file.rewind

        file = prepend_title_page(file, template_name, report, renderer)

        file = append_result_asset_previews(report, file) if report.settings.dig(:task, :file_results_previews)

        report.pdf_file.attach(io: file, filename: 'report.pdf')
        report.update!(pdf_file_processing: false)

        report_path = Rails.application.routes.url_helpers.reports_path
        notification = Notification.create(
          type_of: :deliver,
          title: I18n.t('projects.reports.index.generation.completed_pdf_notification_title'),
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

    private

    def append_result_asset_previews(report, report_file)
      Dir.mktmpdir do |tmp_dir|
        report.report_elements.my_module.each do |my_module_element|
          my_module_element.my_module.results.each do |result|
            next unless result.is_asset && PREVIEW_EXTENSIONS.include?(result.asset.file.blob.filename.extension)

            asset = result.asset
            unless asset.file_pdf_preview.attached?
              PdfPreviewJob.perform_now(asset.id)
              asset.reload
            end
            asset.file_pdf_preview.open(tmpdir: tmp_dir) do |file|
              report_file = merge_pdf_files(file, report_file)
            end
          end
        end
      end
      report_file
    end

    def merge_pdf_files(file, report_file)
      merged_file = Tempfile.new(['report', '.pdf'], binmode: true)
      success = system(
        'pdfunite', report_file.path, file.path, merged_file.path
      )

      unless success && File.file?(merged_file)
        raise StandardError, 'There was an error merging report and PDF file preview'
      end

      report_file.close
      report_file.unlink
      merged_file
    end

    def prepend_title_page(file, template_name, report, renderer)
      total_pages = 0

      IO.popen(['pdfinfo', file.path], 'r+') do |f|
        total_pages = f.read.split("\n")
                       .find { |i| i.split(':')[0] == 'Pages' }
                       .gsub(/[^0-9]/, '')
      end

      title_page = Tempfile.new(['title_page', '.pdf'], binmode: true)
      merged_file = Tempfile.new(['report', '.pdf'], binmode: true)

      title_page << renderer.render(
        pdf: 'report', inline: renderer.render_to_string("reports/templates/#{template_name}/cover.html.erb",
                                                         layout: false,
                                                         locals: { report: report, total_pages: total_pages.to_i }),
                       disable_javascript: false,
                       template: 'reports/report.pdf.erb'
      )

      title_page.rewind

      success = system(
        'pdfunite', title_page.path, file.path, merged_file.path
      )

      raise StandardError, 'There was an error merging report and title page' unless success && File.file?(merged_file)

      file.close
      file.unlink

      title_page.close
      title_page.unlink

      merged_file
    end
  end
end
