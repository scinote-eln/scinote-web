# frozen_string_literal: true

module ActiveStorageConcerns
  extend ActiveSupport::Concern

  def convert_variant_to_base64(variant)
    image_link = if ENV['ACTIVESTORAGE_SERVICE'] == 'amazon'
                   URI.parse(variant.processed.service_url).open.to_a.join
                 else
                   File.open(variant.processed.service_url).to_a.join
                 end
    encoded_data = Base64.strict_encode64(image_link)
    "data:#{variant.image.blob.content_type};base64,#{encoded_data}"
  rescue StandardError => e
    Rails.logger.error e.message
    "data:#{variant.image.blob.content_type};base64,"
  end

  def copy_attachment(target)
    # Target must be empty attachment. Example - asset.file
    temp_file = Tempfile.new
    temp_file.binmode
    blob.download { |chunk| temp_file.write(chunk) }
    temp_file.flush
    temp_file.rewind
    target.attach(io: temp_file, filename: blob.filename, metadata: blob.metadata)
  end
end
