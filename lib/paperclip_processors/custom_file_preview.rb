# frozen_string_literal: true

module Paperclip
  class CustomFilePreview < Processor
    def make
      libreoffice_path = ENV['LIBREOFFICE_PATH'] || 'soffice'
      directory = File.dirname(@file.path)
      basename  = File.basename(@file.path, '.*')
      original_preview_file = File.join(directory, "#{basename}.png")
      dst = TempfileFactory.new.generate("#{basename}.#{options[:format]}")

      begin
        Paperclip.run(
          libreoffice_path,
          "--headless --invisible --convert-to png --outdir #{directory} #{@file.path}"
        )

        convert(
          ":source -resize '#{options[:geometry]}' -format #{options[:format]} #{options[:convert_options]} :dest",
          source: File.expand_path(original_preview_file),
          dest: File.expand_path(dst.path)
        )
      ensure
        File.delete(original_preview_file) if File.file?(original_preview_file)
      end

      dst
    rescue StandardError => e
      raise Paperclip::Error, "There was an error generating document preview - #{e}"
    end
  end
end
