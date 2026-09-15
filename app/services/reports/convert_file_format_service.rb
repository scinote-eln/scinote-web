# frozen_string_literal: true

module Reports
  class ConvertFileFormatService
    def self.convert(original_file, file_format)
      out_dir = File.dirname(original_file.path)
      file_name = "#{File.basename(original_file.path, '.*')}.#{file_format}"
      Rails.logger.info "Starting #{file_format} conversion for file #{original_file.path}..."

      success = run_libreoffice!([original_file.path], out_dir, file_format)

      raise StandardError, "There was an error generating #{file_format} for file #{original_file.path}!" unless success && File.file?(File.join(out_dir, file_name))

      Rails.logger.info("Finished #{file_format} conversion for file #{original_file.path}.")
      File.open(File.join(out_dir, file_name))
    end

    def self.convert_batch(files, file_format)
      return [] if files.empty?

      out_dir = File.dirname(files.first.path)

      Rails.logger.info "Starting #{file_format} conversion"
      success = run_libreoffice!(files.map(&:path), out_dir, file_format)

      expected_paths = files.map { |f| File.join(out_dir, "#{File.basename(f.path, '.*')}.#{file_format}") }
      missing = expected_paths.reject { |p| File.file?(p) }

      raise StandardError, "Failed to convert: #{missing.join(', ')}" unless success && missing.empty?

      expected_paths
    end

    def self.run_libreoffice!(files, out_dir, file_format)
      libreoffice_path = ENV['LIBREOFFICE_PATH'] || 'soffice'

      system(
        'timeout', Constants::PREVIEW_TIMEOUT_SECONDS.to_s,
        libreoffice_path,
        '--headless',
        '--invisible',
        '--convert-to',
        file_format, '--outdir',
        out_dir, *files
      )
    end
  end
end
