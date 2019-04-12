# frozen_string_literal: true

module Paperclip
  class ImageQualityCalculate < Processor
    def initialize(file, options = {}, attachment = nil)
      super
    end

    def make
      if @file && (['image/jpeg', 'image/pjpeg'].include? @file.content_type)
        quality = Paperclip::Processor.new(@file).identify(" -verbose #{@file.path} | grep Quality").split(':')
        quality = (quality[1] || 90).to_f
        # Check format quality
        quality = (quality <= 1 ? quality * 100 : quality).to_i
        @attachment.instance.file_image_quality = quality
        # Asset will be save after all processors finished
      end
      # We need again open file after read quality
      File.new(File.expand_path(@file.path))
    rescue StandardError => e
      raise Paperclip::Error, "There was an error processing the image - #{e}"
    end
  end
end
