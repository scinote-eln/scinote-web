# frozen_string_literal: true

module ExperimentReports
  class GenerateReportService
    PDFUNITE_ENCRYPTED_PDF_ERROR_STRING = 'Unimplemented Feature: Could not merge encrypted files'

    def initialize(experiment, analytical_report, user)
      @experiment = experiment
      @analytical_report = analytical_report
      @user = user
      @tempfiles = []
    end

    def call(my_module_ids)
      my_modules = @experiment.my_modules
                              .readable_by_user(@user)
                              .where(id: my_module_ids)
                              .in_order_of(:id, my_module_ids)

      report_files_paths = my_modules.filter_map do |my_module|
        report = my_module.last_analytical_report
        next unless report

        download_report(report)
      end
      raise StandardError, 'No analytical reports available for generation' if report_files_paths.empty?

      final_report_path = merge_pdf_files(*report_files_paths)

      File.open(final_report_path) do |file|
        @analytical_report.report.attach(io: file, filename: "#{@analytical_report.name}.pdf")
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

    def download_report(report)
      raise StandardError, "Report ##{report.id} has no file attached" unless report.report.attached?

      report_tempfile = new_tempfile(File.basename(report.report.filename.to_s, '.*'))
      report.report.download { |chunk| report_tempfile.write(chunk) }
      report_tempfile.flush
      report_tempfile.rewind

      report_tempfile.path
    rescue StandardError => e
      raise StandardError, "Failed to download report ##{report.id}: #{e.message}"
    end

    def merge_pdf_files(*paths)
      paths = paths.flatten.compact
      raise ArgumentError, 'merge_pdf_files requires at least one path' if paths.empty?
      return paths.first if paths.one?

      merged_file = new_tempfile('report')

      _stdout, stderr, status = Open3.capture3('pdfunite', *paths, merged_file.path)

      if stderr.include?(PDFUNITE_ENCRYPTED_PDF_ERROR_STRING)
        Rails.logger.warn('Cannot merge encrypted PDF, skipping!')
        return paths.first
      elsif !status.success? || !File.file?(merged_file.path) || File.empty?(merged_file.path)
        raise StandardError, "There was an error merging report and PDF file preview (#{stderr})"
      end

      merged_file.path
    rescue Errno::ENOENT
      raise StandardError, 'Required command not found: pdfunite'
    end

    def new_tempfile(basename)
      tempfile = Tempfile.new([basename, '.pdf'], binmode: true)
      @tempfiles << tempfile
      tempfile
    end
  end
end
