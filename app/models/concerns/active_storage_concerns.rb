# frozen_string_literal: true

module ActiveStorageConcerns
  extend ActiveSupport::Concern

  def convert_variant_to_base64(variant)
    encoded_data = Base64.strict_encode64(variant.service.download(variant.processed.key))
    "data:#{variant.image.blob.content_type};base64,#{encoded_data}"
  rescue StandardError => e
    Rails.logger.error e.message
    "data:#{variant.image.blob.content_type};base64,"
  end
end
