# frozen_string_literal: true

module Reports
  class ConvertToDocxService
    def self.convert(original_file)
      out_dir = File.dirname(original_file.path)
      docx_file_name = "#{File.basename(original_file.path, '.*')}.docx"
      Rails.logger.info "Starting docx conversion for file #{original_file.path}..."

      libreoffice_path = ENV['LIBREOFFICE_PATH'] || 'soffice'

      success = system(
        'timeout',
        Constants::PREVIEW_TIMEOUT_SECONDS.to_s,
        libreoffice_path,
        '--headless',
        '--invisible',
        '--convert-to',
        'docx', '--outdir',
        out_dir, original_file.path
      )
      unless success && File.file?(File.join(out_dir, docx_file_name))
        raise StandardError, "There was an error generating docx for file #{original_file.path}!"
      end
      Rails.logger.info("Finished docx conversion for file #{original_file.path}.")
      File.open(File.join(out_dir, docx_file_name))
    end
  end
end
