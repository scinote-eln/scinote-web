# frozen_string_literal: true

module TinyMceImages
  extend ActiveSupport::Concern

  included do
    has_many :tiny_mce_assets,
             as: :object,
             class_name: :TinyMceAsset,
             dependent: :destroy

    def prepare_for_report(field)
      images = tiny_mce_assets
      description = self[field]
      images.each do |image|
        tmp_f = Tempfile.open(image.image_file_name, Rails.root.join('tmp'))
        begin
          image.image.copy_to_local_file(:large, tmp_f.path)
          encoded_image = Base64.strict_encode64(tmp_f.read)
          new_image = "<img class='img-responsive' src='data:image/jpg;base64,#{encoded_image}'>"
          html_description = Nokogiri::HTML(description)
          image_to_update = html_description.css("img[data-token=\"#{Base62.encode(image.id)}\"]")[0]
          image_to_update.replace new_image
          description = html_description.css('body').inner_html.to_s
        ensure
          tmp_f.close
          tmp_f.unlink
        end
      end

      description
    end
  end
end
