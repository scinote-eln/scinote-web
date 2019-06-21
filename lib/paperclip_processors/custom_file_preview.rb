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
        if @file.content_type == 'application/pdf'
          # We use special convert options for PDFs to improve quality and
          # background, we append [0] to convert only the first page
          convert(
            ":source -resize '#{options[:geometry]}' -format #{options[:format]} -flatten -quality 70 :dest",
            source: File.expand_path(@file.path) + '[0]',
            dest: File.expand_path(dst.path)
          )
        else
          Paperclip.run(
            libreoffice_path,
            "--headless --invisible --convert-to png --outdir #{directory} #{@file.path}"
          )

          convert(
            ":source -resize '#{options[:geometry]}' -format #{options[:format]} #{options[:convert_options]} :dest",
            source: File.expand_path(original_preview_file),
            dest: File.expand_path(dst.path)
          )
        end
      ensure
        File.delete(original_preview_file) if File.file?(original_preview_file)
      end

      dst
    rescue StandardError => e
      raise Paperclip::Error, "There was an error generating document preview - #{e}"
    end
  end
end
