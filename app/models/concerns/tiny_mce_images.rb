# frozen_string_literal: true

module TinyMceImages
  extend ActiveSupport::Concern

  included do
    has_many :tiny_mce_assets,
             as: :object,
             class_name: :TinyMceAsset,
             dependent: :destroy

    before_save :clean_tiny_mce_image_urls

<<<<<<< HEAD
<<<<<<< HEAD
    def prepare_for_report(field, base64_encoded_imgs = false)
=======
    def prepare_for_report(field)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    def prepare_for_report(field, base64_encoded_imgs = false)
>>>>>>> Pulled latest release
      description = self[field]

      # Check tinymce for old format
      description = TinyMceAsset.update_old_tinymce(description, self)

      tiny_mce_assets.each do |tm_asset|
<<<<<<< HEAD
<<<<<<< HEAD
        next unless tm_asset&.image&.attached?

        begin
          new_tm_asset_src =
            if base64_encoded_imgs
              tm_asset.convert_variant_to_base64(tm_asset.preview)
            else
              tm_asset.preview.processed.service_url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
            end
        rescue ActiveStorage::FileNotFoundError
          next
        end
=======
        next unless tm_asset&.image&.attached?

<<<<<<< HEAD
<<<<<<< HEAD
        new_tm_asset_src = tm_asset.convert_variant_to_base64(tm_asset.preview)
>>>>>>> Initial commit of 1.17.2 merge
=======
        new_tm_asset_src =
          if base64_encoded_imgs
            tm_asset.convert_variant_to_base64(tm_asset.preview)
          else
            tm_asset.preview.processed.service_url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
          end
>>>>>>> Pulled latest release
=======
        begin
          new_tm_asset_src =
            if base64_encoded_imgs
              tm_asset.convert_variant_to_base64(tm_asset.preview)
            else
              tm_asset.preview.processed.service_url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
            end
        rescue ActiveStorage::FileNotFoundError
          next
        end
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
        html_description = Nokogiri::HTML(description)
        tm_asset_to_update = html_description.css(
          "img[data-mce-token=\"#{Base62.encode(tm_asset.id)}\"]"
        )[0]
        next unless tm_asset_to_update

        tm_asset_to_update.attributes['src'].value = new_tm_asset_src
        description = html_description.css('body').inner_html.to_s
<<<<<<< HEAD
=======
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
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Initial commit of 1.17.2 merge
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

        unless image
          Rails.logger.error "TinyMCE Asset with id #{old_id} not in text"
          next
        end

        image['data-mce-token'] = Base62.encode(new_id)
      end
      update(object_field => parsed_description.css('body').inner_html.to_s)
    end

    def clone_tinymce_assets(target, team)
      cloned_img_ids = []
      tiny_mce_assets.each do |tiny_img|
<<<<<<< HEAD
<<<<<<< HEAD
        next unless tiny_img.image.attached? && tiny_img.image.service.exist?(tiny_img.image.blob.key)

        tiny_img_clone = TinyMceAsset.create(
=======
        tiny_img_clone = TinyMceAsset.new(
          image: tiny_img.image,
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
        next unless tiny_img.image.attached? && tiny_img.image.service.exist?(tiny_img.image.blob.key)

        tiny_img_clone = TinyMceAsset.create(
>>>>>>> Initial commit of 1.17.2 merge
          estimated_size: tiny_img.estimated_size,
          object: target,
          team: team
        )
<<<<<<< HEAD
<<<<<<< HEAD

        tiny_img.duplicate_file(tiny_img_clone)
=======
        tiny_img_clone.save!

>>>>>>> Finished merging. Test on dev machine (iMac).
=======

        tiny_img.duplicate_file(tiny_img_clone)
>>>>>>> Initial commit of 1.17.2 merge
        target.tiny_mce_assets << tiny_img_clone
        cloned_img_ids << [tiny_img.id, tiny_img_clone.id]
      end
      target.reassign_tiny_mce_image_references(cloned_img_ids)
    end

    def copy_unknown_tiny_mce_images
<<<<<<< HEAD
<<<<<<< HEAD
      asset_team_id = Team.search_by_object(self).id
=======
      asset_team_id = Team.find_by_object(self)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      asset_team_id = Team.search_by_object(self).id
>>>>>>> Initial commit of 1.17.2 merge
      return unless asset_team_id

      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]

      image_changed = false
      parsed_description = Nokogiri::HTML(read_attribute(object_field))
      parsed_description.css('img').each do |image|
        if image['data-mce-token']
          asset = TinyMceAsset.find_by_id(Base62.decode(image['data-mce-token']))

          next if asset && (asset.object == self || asset_team_id != asset.team_id)

<<<<<<< HEAD
<<<<<<< HEAD
        else
          url = image['src']
          image_type = FastImage.type(url).to_s
          next unless image_type

          begin
            new_image = Down.download(url, max_size: Rails.configuration.x.file_max_size_mb.megabytes)
          rescue Down::TooLarge => e
            Rails.logger.error e.message
            next
          end

          new_image_filename = Asset.generate_unique_secure_token + '.' + image_type
        end

        new_asset = TinyMceAsset.create(
=======
          new_image = asset.image
=======
>>>>>>> Initial commit of 1.17.2 merge
        else
          url = image['src']
          image_type = FastImage.type(url).to_s
          next unless image_type

          begin
            new_image = Down.download(url, max_size: Rails.configuration.x.file_max_size_mb.megabytes)
          rescue Down::TooLarge => e
            Rails.logger.error e.message
            next
          end

          new_image_filename = Asset.generate_unique_secure_token + '.' + image_type
        end

        new_asset = TinyMceAsset.create(
<<<<<<< HEAD
          image: new_image,
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Initial commit of 1.17.2 merge
          object: self,
          team_id: asset_team_id
        )

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Initial commit of 1.17.2 merge
        new_asset.transaction do
          new_asset.save!
          if image['data-mce-token']
            asset.duplicate_file(new_asset)
          else
            new_asset.image.attach(io: new_image, filename: new_image_filename)
          end
        end

<<<<<<< HEAD
=======
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Initial commit of 1.17.2 merge
        image['src'] = ''
        image['class'] = 'img-responsive'
        image['data-mce-token'] = Base62.encode(new_asset.id)
        image_changed = true
      end
      update(object_field => parsed_description.css('body').inner_html.to_s) if image_changed
    rescue StandardError => e
      Rails.logger.error "Object: #{self.class.name}, id: #{id}, error: #{e.message}"
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
