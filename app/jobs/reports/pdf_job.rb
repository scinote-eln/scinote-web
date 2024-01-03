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
      @report = Report.find(report_id)
      @user = User.find(user_id)
      @file = Tempfile.new(['report', '.pdf'], binmode: true)
      initialize_template
      set_renderer_context
      generate_pdf_content
      process_attach_pdf_report_and_notify
    rescue StandardError => e
      raise e if @report.blank?

      ActiveRecord::Base.no_touching do
        @report.pdf_error!
      end
      Rails.logger.error("Couldn't generate PDF for Report with id: #{@report.id}. Error:\n #{e.message}")
      raise e
    ensure
      Rails.application.config.x.custom_sanitizer_config = nil
      I18n.backend.date_format = nil
      @file.close(true)
    end

    private

    def initialize_template
      @template = if Extends::REPORT_TEMPLATES.key?(@report.settings[:template]&.to_sym)
                    @report.settings[:template]
                  else
                    Extends::REPORT_TEMPLATES.keys.first.to_s
                  end

      raise StandardError, 'Report template not found!' if @template.blank?
    end

    def set_renderer_context
      I18n.backend.date_format = @user.settings[:date_format]
      ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
      proxy = Warden::Proxy.new({}, Warden::Manager.new({}))
      proxy.set_user(@user, scope: :user, store: false)
      ApplicationController.renderer.defaults[:http_host] = Rails.application.routes.default_url_options[:host]
      @renderer = ApplicationController.renderer.new(warden: proxy)
      Rails.application.config.x.custom_sanitizer_config = build_custom_sanitizer_config
    end

    def generate_pdf_content
      @has_cover = Rails.root.join('app', 'views', 'reports', 'templates', @template, 'cover.html.erb').exist?

      render_header_footer_and_report

      gather_styles_and_scripts

      generate_pdf_file
    end

    def render_header_footer_and_report
      @header_html = @renderer.render_to_string(
        template: "reports/templates/#{@template}/header",
        layout: false,
        locals: { report: @report, user: @user, logo: report_logo }
      )
      @footer_html = @renderer.render_to_string(
        template: "reports/templates/#{@template}/footer",
        layout: false,
        locals: { report: @report, user: @user, logo: report_logo }
      )
      @report_html = @renderer.render_to_string(
        template: 'reports/report',
        layout: false,
        assigns: { settings: @report.settings },
        locals: { report: @report, user: @user, has_cover: @has_cover }
      )
    end

    def gather_styles_and_scripts
      css_files = [
        'application',
        'reports_pdf',
        'bootstrap_pack',
        'handsontable.formula'
      ]

      javascript_files = [
        'jquery_bundle',
        'handsontable.full',
        'lodash',
        'numeral',
        'numeric',
        'md5',
        'jstat',
        'formula',
        'parser',
        'ruleJS',
        'big.min',
        'handsontable.formula',
        'reports/content',
        'reports/template_helpers'
      ]

      @style_tag_options = []
      @script_tag_options = []

      @style_tag_options = css_files.map do |file_name|
        { content: fetch_asset_content("#{file_name}.css") }
      end

      @style_tag_options.concat(font_awesome_links)

      @script_tag_options = javascript_files.map do |file_name|
        { content: fetch_asset_content("#{file_name}.js") }
      end
    end

    def generate_pdf_file
      current_margin = extract_margins_from_header ||
                       { top: '2cm', bottom: '2cm', left: '1cm', right: '1.5cm' }

      cover_pages_shift = cover_page_shift_from_template

      Grover.new(
        @report_html,
        format: 'A4',
        print_background: true,
        margin: current_margin,
        display_header_footer: true,
        header_template: @header_html,
        footer_template: @footer_html,
        style_tag_options: @style_tag_options,
        script_tag_options: @script_tag_options,
        page_ranges: "#{cover_pages_shift}-999999",
        emulate_media: 'screen',
        display_url: Rails.application.routes.default_url_options[:host]
      ).to_pdf(@file.path)
    end

    def process_attach_pdf_report_and_notify
      @file.rewind
      @file = prepend_title_page if @has_cover
      @file = append_result_asset_previews if @report.settings.dig(:task, :file_results_previews)

      @report.pdf_file.attach(io: @file, filename: 'report.pdf')
      @report.pdf_ready!

      create_notification_for_user
    end

    def create_notification_for_user
      report_path = Rails.application.routes.url_helpers
                         .reports_path(team: @report.team.id, preview_report_id: @report.id, preview_type: :pdf)
      DeliveryNotification.send_notifications(
        {
          title: I18n.t('projects.reports.index.generation.completed_pdf_notification_title'),
          message: I18n.t('projects.reports.index.generation.completed_notification_message',
                          report_link: "<a href='#{report_path}'>#{escape_input(@report.name)}</a>",
                          team_name: escape_input(@report.team.name)),
          subject_id: @report.id,
          subject_class: 'Report',
          subject_name: @report.name,
          report_type: 'pdf',
          user: @user
        }
      )
    end

    def append_result_asset_previews
      Dir.mktmpdir do |tmp_dir|
        @report.report_elements.my_module.each do |my_module_element|
          next unless can_read_my_module?(@user, my_module_element.my_module)

          results = my_module_element.my_module.results
          order_results_for_report(results, @report.settings.dig(:task, :result_order)).each do |result|
            result.assets.each do |asset|
              next unless PREVIEW_EXTENSIONS.include?(asset.file.blob.filename.extension)

              if !asset.file_pdf_preview.attached? || (asset.file.created_at > asset.file_pdf_preview.created_at)
                PdfPreviewJob.perform_now(asset.id)
                asset.reload
              end
              asset.file_pdf_preview.open(tmpdir: tmp_dir) do |file|
                @file = merge_pdf_files(file, @file)
              end
            end
          end
        end
      end
      @file
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

    def prepend_title_page
      unless File.exist?(Rails.root.join('app', 'views', 'reports', 'templates', @template, 'cover.html.erb'))
        return @file
      end

      total_pages = 0

      IO.popen(['pdfinfo', @file.path], 'r+') do |f|
        total_pages = f.read.split("\n")
                       .find { |i| i.split(':')[0] == 'Pages' }
                       .gsub(/[^0-9]/, '')
      end

      title_page = Tempfile.new(['title_page', '.pdf'], binmode: true)
      merged_file = Tempfile.new(['report', '.pdf'], binmode: true)

      title_page_html = @renderer.render_to_string(
        template: "reports/templates/#{@template}/cover",
        layout: false,
        formats: :html,
        locals: { report: @report, total_pages: total_pages.to_i, logo: report_logo }
      )

      Grover.new(
        title_page_html,
        format: 'A4',
        style_tag_options: @style_tag_options,
        script_tag_options: @script_tag_options,
        emulate_media: 'screen',
        print_background: true,
        display_url: Rails.application.routes.default_url_options[:host]
      ).to_pdf(title_page.path)

      title_page.rewind

      success = system(
        'pdfunite', title_page.path, @file.path, merged_file.path
      )

      raise StandardError, 'There was an error merging report and title page' unless success && File.file?(merged_file)

      @file.close(true)
      title_page.close(true)

      merged_file
    end

    def report_logo
      'scinote_logo.svg'
    end

    def build_custom_sanitizer_config
      sanitizer_config = Constants::INPUT_SANITIZE_CONFIG.deep_dup
      sanitizer_config[:protocols] = {
        'a' => { 'href' => ['http', 'https', :relative] },
        'img' => { 'src' => %w(data) }
      }
      sanitizer_config
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

    def fetch_asset_content(asset_name)
      Rails.application
           .assets_manifest
           .find_sources(asset_name)
           .first
           .to_s
           .force_encoding(Encoding::UTF_8)
    end

    def extract_margins_from_header
      header_file_path = Rails.root.join('app', 'views', 'reports', 'templates', @template, 'header.html.erb')
      return nil unless header_file_path.exist?

      content = File.read(header_file_path)

      margin_comment = content.match(/<!--\s*margins:(.*)\s*-->/)
      return nil unless margin_comment

      margins = {}
      margin_comment[1].split(',').each do |margin_pair|
        key, value = margin_pair.split(':').map(&:strip)
        margins[key.to_sym] = value
      end

      margins
    end

    def cover_page_shift_from_template
      cover_file_path = Rails.root.join('app', 'views', 'reports', 'templates', @template, 'cover.html.erb')
      return 1 unless cover_file_path.exist?

      content = File.read(cover_file_path)

      cover_pages_comment = content.match(/<!--\s*cover_pages_count:(\d+)\s*-->/)
      return 2 unless cover_pages_comment

      cover_pages_comment[1].to_i + 1
    end
  end
end
