# frozen_string_literal: true

module ImageVariantProcessing
  extend ActiveSupport::Concern

  def convert_variant_to_base64(variant)
    image_link = if ENV['ACTIVESTORAGE_SERVICE'] == 'amazon'
                   URI.parse(variant.processed.service_url).open.to_a.join
                 else
                   File.open(variant.processed.service_url).to_a.join
                 end
    encoded_data = Base64.strict_encode64(image_link)
    "data:#{variant.image.blob.content_type};base64,#{encoded_data}"
  end
end
