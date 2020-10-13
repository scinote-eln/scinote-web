# frozen_string_literal: true

module Reports
  class Utils
    def self.link_prepare(scinote_url, link)
      link[0] == '/' ? scinote_url + link : link
    end

    def self.image_path(attachment)
      attachment.service_url
    end

    def self.calculate_color_hsp(color)
      return 255 if color.length != 7

      color = color.delete('#').scan(/.{1,2}/)
      rgb = color.map(&:hex)
      Math.sqrt(
        0.299 * (rgb[0]**2) +
          0.587 * (rgb[1]**2) +
          0.114 * (rgb[2]**2)
      )
    end
  end
end
