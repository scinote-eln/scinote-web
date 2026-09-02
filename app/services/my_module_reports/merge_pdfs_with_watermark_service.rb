# frozen_string_literal: true

module MyModuleReports
  class MergePdfsWithWatermarkService
    include Canaid::Helpers::PermissionsHelper
    PDFUNITE_ENCRYPTED_PDF_ERROR_STRING = 'Unimplemented Feature: Could not merge encrypted files'

    def initialize(user, my_module_report, asset_ids, header_text, footer_text, add_numarization, add_blank_page)
      @user = user
      @my_module_report = my_module_report
      @my_module = @my_module_report.my_module
      @asset_ids = asset_ids
      @header_text = header_text
      @footer_text = footer_text
      @add_numarization = add_numarization
      @add_blank_page = add_blank_page
      @tempfiles = []
    end

    def generate!
      load_report!

      assets = (@my_module.assets_in_steps.pdfs.where(id: @asset_ids) +
                @my_module.assets_in_results.pdfs.where(id: @asset_ids)).in_order_of(:id, @asset_ids)

      assets.each do |asset|
        next unless can_read_asset?(@user, asset)

        process_asset!(asset)
      end

      File.open(@report) do |file|
        @my_module_report.report.attach(io: file, filename: @original_filename)
      end
    ensure
      @tempfiles.each do |tempfile|
        tempfile.close
        tempfile.unlink
      rescue Errno::ENOENT
        # already removed, nothing to do
      end
    end

    private

    def load_report!
      @original_filename = @my_module_report.report.filename.to_s
      report_tempfile = new_tempfile(File.basename(@original_filename, '.*'), File.extname(@original_filename))
      @my_module_report.report.download { |chunk| report_tempfile.write(chunk) }
      report_tempfile.flush
      report_tempfile.rewind
      @report = report_tempfile.path
    end

    def process_asset!(asset)
      asset.blob.open do |tempfile|
        pages, format, orientation = pdf_info(tempfile.path)
        content_path = tempfile.path

        if @add_blank_page
          blank_path = Rails.root.join("app/assets/report_templates/#{format}_#{orientation}_empty_page.pdf")
          content_path = merge_pdf_files(content_path, blank_path.to_s)
          pages += 1
        end

        if @header_text.present? || @footer_text.present? || @add_numarization
          page_entries = Array.new(pages) { |i| { header: @header_text, footer: footer(i + 1) } }
          watermark_path = render_watermark(page_entries, format, orientation)
          content_path = overlay_watermark(content_path, watermark_path)
        end

        @report = merge_pdf_files(@report, content_path)
      end
    rescue StandardError => e
      raise e.class, "#{e.message} (asset_id: #{asset.id})", e.backtrace
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
        report.add_field :REPORT_FOOTER, page_entry[:footer]
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
        Rails.logger.warn("Cannot merge encrypted PDF #{head_path}, skipping!")
        return tail_path
      elsif !status.success? || !File.file?(merged_file.path) || File.empty?(merged_file.path)
        raise StandardError, "There was an error merging report and PDF file preview (#{stderr})"
      end

      merged_file.path
    end

    def footer(index)
      return @footer_text unless @add_numarization
      return index.to_s if @footer_text.blank?

      "#{@footer_text}_#{index}"
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
