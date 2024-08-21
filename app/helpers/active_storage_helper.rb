# frozen_string_literal: true

module ActiveStorageHelper
  def image_preview_format(blob)
    if ['image/jpeg', 'image/jpg'].include?(blob&.content_type)
      :jpeg
    else
      :png
    end
  end
end
