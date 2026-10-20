# frozen_string_literal: true

module MyModuleReports
  class MergePdfsWithWatermarkService
    include Canaid::Helpers::PermissionsHelper
    PDFUNITE_ENCRYPTED_PDF_ERROR_STRING = 'Unimplemented Feature: Could not merge encrypted files'

    def initialize(user, analytical_report)
      @user = user
      @analytical_report = analytical_report
      @my_module = @analytical_report.reference
      @asset_groups = analytical_report.params['asset_groups']
      @header_text = analytical_report.params['header']
      @display_attachment_references = analytical_report.params['display_attachment_references']
      @add_reference_page_numbers = analytical_report.params['add_reference_page_numbers']
      @display_attachment_groups = analytical_report.params['display_attachment_groups']
      @add_group_numeration = analytical_report.params['add_group_numeration']
      @add_blank_page = analytical_report.params['add_blank_page_after_group']

      @tempfiles = []
    end

    def generate!
      load_report!

      @asset_groups.each do |asset_group|
        group_type, asset_ids = asset_group.values_at('type', 'asset_ids')

        assets, parents = case group_type
                          when 'step'
                            [@my_module.assets_in_steps.with_active_step, @my_module.steps]
                          when 'result'
                            [@my_module.assets_in_results.with_active_result, @my_module.results]
                          else
                            next
                          end

        readable_assets = assets.pdfs.active
                                .in_order_of(:id, asset_ids)
                                .select { |asset| can_read_asset?(@user, asset) }
        next if readable_assets.empty?

        footer_text = parents.where(id: asset_group['id']).pick(:name).to_s
        last_index = readable_assets.size - 1
        current_page = 0

        readable_assets.each_with_index do |asset, i|
          current_page = process_asset!(asset, footer_text, current_page, i == last_index)
        end
      end

      File.open(@report, 'rb') do |file|
        @analytical_report.report.attach(io: file, filename: @original_filename)
      end
    ensure
      @tempfiles&.each(&:close!)
    end

    private

    def load_report!
      @original_filename = @analytical_report.report.filename.to_s
      report_tempfile = new_tempfile(File.basename(@original_filename, '.*'), File.extname(@original_filename))
      @analytical_report.report.download { |chunk| report_tempfile.write(chunk) }
      report_tempfile.flush
      report_tempfile.rewind
      @report = report_tempfile.path
    end

    def process_asset!(asset, footer_text, current_page, last_asset)
      asset.blob.open do |tempfile|
        pages, format, orientation = pdf_info(tempfile.path)
        content_path = tempfile.path

        if @header_text.present? || @display_attachment_references || @display_attachment_groups
          file_name = "#{I18n.t('atwho.tags.file')}#{asset.file_title || asset.file_name}" if @display_attachment_references

          page_entries = Array.new(pages) do |i|
            {
              header: @header_text,
              group_footer: @display_attachment_groups ? footer(footer_text, @add_group_numeration, current_page + i + 1) : '',
              reference_footer: @display_attachment_references ? footer(file_name, @add_reference_page_numbers, i + 1) : ''
            }
          end

          watermark_path = render_watermark(page_entries, format, orientation)
          content_path = overlay_watermark(content_path, watermark_path)
        end

        current_page += pages
        content_path = add_blank_page(content_path, footer_text, current_page, format, orientation) if last_asset && @add_blank_page
        @report = merge_pdf_files(@report, content_path)
        current_page
      end
    rescue StandardError => e
      raise e.exception("#{e.message} (asset_id: #{asset.id})")
    end

    def pdf_info(path)
      output, stderr, status = run_command('pdfinfo', path)
      raise StandardError, "pdfinfo failed: #{stderr.presence || output}" unless status.success?

      data = output.each_line.with_object({}) do |line, hash|
        key, value = line.split(':', 2)
        hash[key.strip] = value.strip if key && value
      end

      pages = data['Pages'].to_i
      raise StandardError, "Could not parse page count: #{data['Pages'].inspect}" if pages.zero?

      match = data['Page size']&.match(/([\d.]+)\s*x\s*([\d.]+)\s*pts(?:\s*\(([^)]+)\))?/)
      raise StandardError, "Could not parse page size: #{data['Page size']}" unless match

      width = match[1].to_f
      height = match[2].to_f
      extra  = match[3]

      parts = extra&.split(',')&.map(&:strip) || []
      format = parts.find { |p| p !~ /portrait|landscape/i } || 'Custom'
      orientation = if parts.any? { |p| p =~ /landscape/i }
                      'landscape'
                    elsif parts.any? { |p| p =~ /portrait/i }
                      'portrait'
                    else
                      width > height ? 'landscape' : 'portrait'
                    end
      format = format == 'letter' ? 'letter' : 'A4'

      [pages, format, orientation]
    end

    def render_watermark(page_entries, format, orientation)
      template_path = Rails.root.join("app/assets/report_templates/odt_#{format}_#{orientation}_watermark_template.odt")

      odt_files = page_entries.map { |page_entry| generate_filled_watermark_odt(template_path, page_entry) }
      pdf_paths = Reports::ConvertFileFormatService.convert_batch(odt_files, 'pdf')

      merge_pdf_files(*pdf_paths)
    end

    def generate_filled_watermark_odt(template_path, page_entry)
      filled_odt = new_tempfile('watermark', '.odt')

      ODFReport::Report.new(template_path.to_s) do |report|
        report.add_field :REPORT_HEADER, page_entry[:header]
        report.add_field :REPORT_FOOTER_REFERENCE, page_entry[:reference_footer]
        report.add_field :REPORT_FOOTER_GROUP, page_entry[:group_footer]
      end.generate(filled_odt.path)

      filled_odt
    end

    def overlay_watermark(source_path, watermark_path)
      output_tempfile = new_tempfile('watermarked_output', '.pdf')

      stdout, stderr, status = run_command(
        'qpdf', source_path, '--overlay', watermark_path, '--', output_tempfile.path
      )

      # qpdf exit codes: 0 = success, 3 = succeeded with warnings (output is still valid), anything else is a real failure.
      raise StandardError, "qpdf overlay failed: #{stderr.presence || stdout}" unless [0, 3].include?(status.exitstatus)
      raise StandardError, "qpdf overlay produced no output: #{stderr.presence || stdout}" unless File.file?(output_tempfile.path) && !File.empty?(output_tempfile.path)

      output_tempfile.path
    end

    def merge_pdf_files(*paths)
      paths = paths.flatten.compact
      raise ArgumentError, 'merge_pdf_files requires at least one path' if paths.empty?
      return paths.first if paths.one?

      merged_file = new_tempfile('report', '.pdf')

      _stdout, stderr, status = run_command('pdfunite', *paths, merged_file.path)

      if stderr.include?(PDFUNITE_ENCRYPTED_PDF_ERROR_STRING)
        Rails.logger.warn('Cannot merge encrypted PDF, skipping!')
        return paths.first
      elsif !status.success? || !File.file?(merged_file.path) || File.empty?(merged_file.path)
        raise StandardError, "There was an error merging report and PDF file preview (#{stderr})"
      end

      merged_file.path
    end

    def add_blank_page(content_path, footer_text, current_page, format, orientation)
      blank_path = Rails.root.join('app/assets/report_templates', "#{format}_#{orientation}_empty_page.pdf").to_s
      raise ArgumentError, "Missing blank page template: #{format}_#{orientation}" unless File.exist?(blank_path)

      if @header_text.present? || @display_attachment_groups
        page_entry = {
          header: @header_text,
          group_footer: @display_attachment_groups ? footer(footer_text, @add_group_numeration, current_page + 1) : '',
          reference_footer: ''
        }
        blank_path = overlay_watermark(blank_path, render_watermark([page_entry], format, orientation))
      end

      merge_pdf_files(content_path, blank_path)
    end

    def footer(footer_text, add_numarization, index)
      return footer_text unless add_numarization
      return index.to_s if footer_text.blank?

      "#{footer_text}_#{index}"
    end

    def run_command(*cmd)
      Open3.capture3(*cmd)
    rescue Errno::ENOENT
      raise StandardError, "Required command not found: #{cmd.first}"
    end

    def new_tempfile(basename, suffix)
      tempfile = Tempfile.new([basename, suffix], binmode: true)
      @tempfiles << tempfile
      tempfile
    end
  end
end
