# frozen_string_literal: true

module Paperclip
  class ImageQualityCalculate < Processor
    def initialize(file, options = {}, attachment = nil)
      super
    end

    def make
      if @file && (['image/jpeg', 'image/pjpeg'].include? @file.content_type)
        quality = Paperclip::Processor.new(@file).identify(" -format '%Q' #{@file.path}")
        @attachment.instance.file_image_quality = quality.to_i
        # Asset will be save after all processors finished
      end

      # We have to create a new temp file otherwise the postprocessing logic will
      # delete the original file, leaving no files to postprocess for styles
      current_format = File.extname(attachment.instance.file_file_name)
      basename = File.basename(@file.path, current_format)
      tempfile = Tempfile.new([basename, current_format].compact.join('.'))

      begin
        tempfile.write(File.read(@file.path))
        tempfile.flush
        tempfile
      rescue StandardError => e
        tempfile.close
        tempfile.unlink
        raise Paperclip::Error, "There was an error writing to tempfile - #{e}"
      end
    rescue StandardError => e
      raise Paperclip::Error, "There was an error processing the image - #{e}"
    end
  end
end
