# frozen_string_literal: true

module TinyMceImages
  extend ActiveSupport::Concern

  included do
    has_many :tiny_mce_assets,
             as: :object,
             class_name: :TinyMceAsset,
             dependent: :destroy

    def prepare_for_report(field)
      description = self[field]
      tiny_mce_assets.each do |tm_asset|
        tmp_f = Tempfile.open(tm_asset.image_file_name, Rails.root.join('tmp'))
        begin
          tm_asset.image.copy_to_local_file(:large, tmp_f.path)
          encoded_tm_asset = Base64.strict_encode64(tmp_f.read)
          new_tm_asset = "<img class='img-responsive'
            src='data:image/jpg;base64,#{encoded_tm_asset}' >"
          html_description = Nokogiri::HTML(description)
          tm_asset_to_update = html_description.css(
            "img[data-mce-token=\"#{Base62.encode(tm_asset.id)}\"]"
          )[0]
          tm_asset_to_update.replace new_tm_asset
          description = html_description.css('body').inner_html.to_s
        ensure
          tmp_f.close
          tmp_f.unlink
        end
      end
      description
    end

    def tinymce_render(field)
      TinyMceAsset.generate_url(self[field])
    end
  end
end
