# frozen_string_literal: true

module TinyMceImages
  extend ActiveSupport::Concern

  included do
    has_many :tiny_mce_assets,
             as: :object,
             class_name: :TinyMceAsset,
             dependent: :destroy

    before_save :clean_tiny_mce_image_urls

    def prepare_for_report(field)
      description = self[field]

      # Check tinymce for old format
      description = TinyMceAsset.update_old_tinymce(description, self)

      tiny_mce_assets.each do |tm_asset|
        tmp_f = Tempfile.open(tm_asset.image_file_name, Rails.root.join('tmp'))
        begin
          tm_asset.image.copy_to_local_file(:large, tmp_f.path)
          encoded_tm_asset = Base64.strict_encode64(tmp_f.read)
          new_tm_asset_src = "data:image/jpg;base64,#{encoded_tm_asset}"
          html_description = Nokogiri::HTML(description)
          tm_asset_to_update = html_description.css(
            "img[data-mce-token=\"#{Base62.encode(tm_asset.id)}\"]"
          )[0]
          next unless tm_asset_to_update

          tm_asset_to_update.attributes['src'].value = new_tm_asset_src
          description = html_description.css('body').inner_html.to_s
        ensure
          tmp_f.close
          tmp_f.unlink
        end
      end
      description
    end

    def tinymce_render(field)
      TinyMceAsset.generate_url(self[field], self)
    end

    # Takes array of old/new TinyMCE asset ID pairs
    # and updates references in assosiated object's description
    def reassign_tiny_mce_image_references(images = [])
      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]
      description = read_attribute(object_field)

      # Check tinymce for old format
      description = TinyMceAsset.update_old_tinymce(description, self)

      parsed_description = Nokogiri::HTML(description)
      images.each do |image|
        old_id = image[0]
        new_id = image[1]
        image = parsed_description.at_css("img[data-mce-token=\"#{Base62.encode(old_id)}\"]")
        image['data-mce-token'] = Base62.encode(new_id)
      end
      update(object_field => parsed_description.css('body').inner_html.to_s)
    end

    def clone_tinymce_assets(target, team)
      cloned_img_ids = []
      tiny_mce_assets.each do |tiny_img|
        tiny_img_clone = TinyMceAsset.new(
          image: tiny_img.image,
          estimated_size: tiny_img.estimated_size,
          object: target,
          team: team
        )
        tiny_img_clone.save!

        target.tiny_mce_assets << tiny_img_clone
        cloned_img_ids << [tiny_img.id, tiny_img_clone.id]
      end
      target.reassign_tiny_mce_image_references(cloned_img_ids)
    end

    private

    def clean_tiny_mce_image_urls
      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]
      return unless changed.include?(object_field.to_s)

      image_changed = false
      parsed_description = Nokogiri::HTML(read_attribute(object_field))
      parsed_description.css('img[data-mce-token]').each do |image|
        image['src'] = ''
        image['class'] = 'img-responsive'
        image_changed = true
      end
      self[object_field] = parsed_description.to_html if image_changed
    end
  end
end
