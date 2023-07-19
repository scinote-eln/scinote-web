# frozen_string_literal: true

module ActiveStorage
  class Analyzer::ImageAnalyzer::CustomImageMagick < Analyzer::ImageAnalyzer::ImageMagick
    JPEG_MIME_TYPES = ['image/jpeg', 'image/pjpeg'].freeze

    def self.accept?(blob)
      blob.content_type.in?(JPEG_MIME_TYPES) && blob.attachments.take.record_type == 'Asset'
    end

    def metadata
      read_image do |image|
        quality = image.identify { |b| b.format('%Q') }.to_i
        blob.attachments.take.record.update(file_image_quality: quality)

        if rotated_image?(image)
          { width: image.height, height: image.width }
        else
          { width: image.width, height: image.height }
        end
      end
    end
  end
end
