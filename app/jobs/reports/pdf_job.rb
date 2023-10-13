# frozen_string_literal: true

module Reports
  class PdfJob < ApplicationJob
    extend InputSanitizeHelper
    include InputSanitizeHelper
    include ReportsHelper
    include Canaid::Helpers::PermissionsHelper
    include FailedDeliveryNotifiableJob

    PDFUNITE_ENCRYPTED_PDF_ERROR_STRING = 'Unimplemented Feature: Could not merge encrypted files'

    queue_as :reports

    PREVIEW_EXTENSIONS = %w(docx pdf).freeze

    def perform(report_id, user_id:)
      report = Report.find(report_id)
      user = User.find(user_id)
      file = Tempfile.new(['report', '.pdf'], binmode: true)
      begin
        template =
          if Extends::REPORT_TEMPLATES.key?(report.settings[:template]&.to_sym)
            report.settings[:template]
          else
            Extends::REPORT_TEMPLATES.keys.first.to_s
          end

        raise StandardError, 'Report template not found!' if template.blank?

        I18n.backend.date_format = user.settings[:date_format]
        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
        proxy.set_user(user, scope: :user, store: false)
        ApplicationController.renderer.defaults[:http_host] = Rails.application.routes.default_url_options[:host]
        renderer = ApplicationController.renderer.new(warden: proxy)

        file << renderer.render(
          pdf: 'report', header: { html: { template: "reports/templates/#{template}/header",
                                           locals: { report: report, user: user, logo: report_logo },
                                           layout: 'reports/footer_header' } },
                         footer: { html: { template: "reports/templates/#{template}/footer",
                                           locals: { report: report, user: user, logo: report_logo },
                                           layout: 'reports/footer_header' } },
                         assigns: { settings: report.settings },
                         locals: { report: report },
                         disable_javascript: false,
                         template: 'reports/report',
                         formats: :pdf
        )

        file.rewind

        file = prepend_title_page(file, template, report, renderer)

        file = append_result_asset_previews(report, file, user) if report.settings.dig(:task, :file_results_previews)

        report.pdf_file.attach(io: file, filename: 'report.pdf')
        report.pdf_ready!

        report_path = Rails.application.routes.url_helpers
                           .reports_path(team: report.team.id, preview_report_id: report.id, preview_type: :pdf)

        DeliveryNotification.with(
          title: I18n.t('projects.reports.index.generation.completed_pdf_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
                          team_name: escape_input(report.team.name))
        ).deliver(user)
      ensure
        I18n.backend.date_format = nil
        file.close(true)
      end
    rescue StandardError => e
      raise e if report.blank?

      ActiveRecord::Base.no_touching do
        report.pdf_error!
      end
      Rails.logger.error("Couldn't generate PDF for Report with id: #{report.id}. Error:\n #{e.message}")
      raise e
    end

    private

    def append_result_asset_previews(report, report_file, user)
      Dir.mktmpdir do |tmp_dir|
        report.report_elements.my_module.each do |my_module_element|
          next unless can_read_my_module?(user, my_module_element.my_module)

          results = my_module_element.my_module.results
          order_results_for_report(results, report.settings.dig(:task, :result_order)).each do |result|
            result.assets.each do |asset|
              next unless PREVIEW_EXTENSIONS.include?(asset.file.blob.filename.extension)

              if !asset.file_pdf_preview.attached? || (asset.file.created_at > asset.file_pdf_preview.created_at)
                PdfPreviewJob.perform_now(asset.id)
                asset.reload
              end
              asset.file_pdf_preview.open(tmpdir: tmp_dir) do |file|
                report_file = merge_pdf_files(file, report_file)
              end
            end
          end
        end
      end
      report_file
    end

    def merge_pdf_files(file, report_file)
      merged_file = Tempfile.new(['report', '.pdf'], binmode: true)

      _output, error, status = Open3.capture3(
        'pdfunite', report_file.path, file.path, merged_file.path
      )

      # don't raise error if the issue was an encrypted pdf, which pdfunite doesn't support
      if error.include?(PDFUNITE_ENCRYPTED_PDF_ERROR_STRING)
        Rails.logger.warn("Cannot merge encrypted PDF #{file.path}, skipping!")

        file.close(true)
        merged_file.close(true)

        # return the report file unchanged, as no merge was done
        return report_file
      elsif !status.success? || !File.file?(merged_file)
        raise StandardError, "There was an error merging report and PDF file preview (#{error})"
      end

      file.close(true)
      report_file.close(true)

      merged_file
    end

    def prepend_title_page(file, template, report, renderer)
      unless File.exist?(Rails.root.join('app', 'views', 'reports', 'templates', template, 'cover'))
        return file
      end

      total_pages = 0

      IO.popen(['pdfinfo', file.path], 'r+') do |f|
        total_pages = f.read.split("\n")
                       .find { |i| i.split(':')[0] == 'Pages' }
                       .gsub(/[^0-9]/, '')
      end

      title_page = Tempfile.new(['title_page', '.pdf'], binmode: true)
      merged_file = Tempfile.new(['report', '.pdf'], binmode: true)

      title_page << renderer.render(
        pdf: 'report', inline: renderer.render_to_string("reports/templates/#{template}/cover",
                                                         layout: false,
                                                         formats: :html,
                                                         locals: { report: report, total_pages: total_pages.to_i, logo: report_logo }),
                       disable_javascript: false,
                       template: 'reports/report',
                       formats: :pdf
      )

      title_page.rewind

      success = system(
        'pdfunite', title_page.path, file.path, merged_file.path
      )

      raise StandardError, 'There was an error merging report and title page' unless success && File.file?(merged_file)

      file.close(true)
      title_page.close(true)

      merged_file
    end

    def report_logo
      'scinote_logo.svg'
    end

    # Overrides method from FailedDeliveryNotifiableJob concern
    def failed_notification_title
      I18n.t('projects.reports.index.generation.error_pdf_notification_title')
    end

    # Overrides method from FailedDeliveryNotifiableJob concern
    def failed_notification_message
      report = Report.find_by(id: arguments.first)
      return '' if report.blank?

      report_path =
        if report.pdf_file.attached?
          Rails.application.routes.url_helpers
               .reports_path(team: report.team.id, preview_report_id: report.id, preview_type: :pdf)
        else
          Rails.application.routes.url_helpers.reports_path(team: report.team.id)
        end

      I18n.t('projects.reports.index.generation.error_notification_message',
             report_link: "<a href='#{report_path}'>#{escape_input(report.name)}</a>",
             team_name: escape_input(report.team.name))
    end
  end
end
