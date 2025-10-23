# frozen_string_literal: true

module TinyMceImages
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength:
  included do
    has_many :tiny_mce_assets,
             as: :object,
             class_name: :TinyMceAsset,
             dependent: :destroy

    before_validation :extract_base64_images
    before_save :clean_tiny_mce_image_urls
    after_create :ensure_extracted_image_object_references

    def prepare_for_report(field, export_all: false)
      description = self[field]

      # Check tinymce for old format
      description = TinyMceAsset.update_old_tinymce(description, self)

      tiny_mce_assets.each do |tm_asset|
        next unless tm_asset&.image&.attached?

        html_description = Nokogiri::HTML(description)
        tm_asset_to_update = html_description.css(
          "img[data-mce-token=\"#{Base62.encode(tm_asset.id)}\"]"
        )[0]
        next unless tm_asset_to_update

        begin
          variant = tm_asset.image.variant(resize_to_limit: Constants::LARGE_PIC_FORMAT)
          resized_asset = ActiveStorage::Variant.new(variant.blob, variant.variation).processed

          width_attr = tm_asset_to_update.attributes['width']
          height_attr = tm_asset_to_update.attributes['height']

          if width_attr && height_attr && (width_attr.value.to_i >= Constants::LARGE_PIC_FORMAT[0] ||
                                          height_attr.value.to_i >= Constants::LARGE_PIC_FORMAT[1])
            width_attr.value = resized_asset.image.blob.metadata['width'].to_s
            height_attr.value = resized_asset.image.blob.metadata['height'].to_s
          end

          tm_asset_to_update.attributes['src'].value = convert_to_base64(resized_asset)
        rescue StandardError => e
          Rails.logger.error(e)
        end

        description = html_description.css('body').inner_html.to_s
      end
      description
    end

    def tinymce_render(field)
      TinyMceAsset.generate_url(self[field], self)
    end

    def shareable_tinymce_render(field)
      TinyMceAsset.generate_url(self[field], self, is_shared_object: true)
    end

    # Takes array of old/new TinyMCE asset ID pairs
    # and updates references in assosiated object's description
    def reassign_tiny_mce_image_references(images = [])
      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]

      return unless object_field

      description = read_attribute(object_field)

      return unless description

      # Check tinymce for old format
      description = TinyMceAsset.update_old_tinymce(description, self)

      parsed_description = Nokogiri::HTML(description)
      images.each do |image|
        old_id = image[0]
        new_id = image[1]
        image_elements = parsed_description.css("img[data-mce-token=\"#{Base62.encode(old_id)}\"]")

        if image_elements.blank?
          Rails.logger.error "TinyMCE Asset with id #{old_id} not in text"
          next
        end

        image_elements.each do |image_element|
          image_element['data-mce-token'] = Base62.encode(new_id)
        end
      end
      update(object_field => parsed_description.css('body').inner_html.to_s)
    end

    def clone_tinymce_assets(target, team)
      cloned_img_ids = []
      tiny_mce_assets.each do |tiny_img|
        next unless tiny_img.image.attached? && tiny_img.image.service.exist?(tiny_img.image.blob.key)

        tiny_img_clone = TinyMceAsset.create(
          estimated_size: tiny_img.estimated_size,
          object: target,
          team: team
        )

        tiny_img.duplicate_file(tiny_img_clone)
        target.tiny_mce_assets << tiny_img_clone
        cloned_img_ids << [tiny_img.id, tiny_img_clone.id]
      end
      target.reassign_tiny_mce_image_references(cloned_img_ids)
    end

    def copy_unknown_tiny_mce_images(user)
      asset_team_id = team.id
      return unless asset_team_id

      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]

      image_changed = false
      parsed_description = Nokogiri::HTML(read_attribute(object_field))
      parsed_description.css('img').each do |image|
        asset = image['data-mce-token'].presence && TinyMceAsset.find_by(id: Base62.decode(image['data-mce-token']))

        if asset
          next if asset.object == self
          next unless asset.can_read?(user)
        else
          image_type = nil
          begin
            uri = URI.parse(image['src'])
            if uri.scheme != 'https'
              uri.scheme = Rails.application.config.force_ssl ? 'https' : 'http'
            end
            image_type = FastImage.type(uri.to_s).to_s
            next unless image_type

            new_image = Down.download(uri.to_s, max_size: Rails.configuration.x.file_max_size_mb.megabytes)
          rescue StandardError => e
            Rails.logger.error e.message
            next
          end

          new_image_filename = Asset.generate_unique_secure_token + '.' + image_type
        end

        new_asset = TinyMceAsset.create(
          object: self,
          team_id: asset_team_id
        )

        new_asset.transaction do
          new_asset.save!
          if asset
            asset.duplicate_file(new_asset)
          else
            new_asset.image.attach(io: new_image, filename: new_image_filename)
          end
        end

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
      self[object_field] = parsed_description.to_html.strip if image_changed
    end

    def extract_base64_images
      # extracts and uploads any base64 encoded images,
      # so they get stored as files instead of directly in the text
      @extracted_base64_images = []

      object_field = Extends::RICH_TEXT_FIELD_MAPPINGS[self.class.name]
      return unless object_field

      sanitized_text = public_send(object_field)
      return unless sanitized_text

      ActiveRecord::Base.transaction do
        sanitized_text.scan(%r{src=['"](data:image/[^;]+;base64[^"]+)['"]}i).flatten.each do |base64_src|
          next unless team.id

          base64_data_parts = base64_src.split('base64,')
          base64_file_extension =
            MIME::Types[
              base64_data_parts.first.split(':').last[0..-2]
            ].first.preferred_extension
          base64_data = base64_data_parts.last

          tiny_image = TinyMceAsset.create!(
            team:,
            object_id: id,
            object_type: self.class.name,
            saved: true
          )

          tiny_image.image.attach(
            io: StringIO.new(Base64.decode64(base64_data)),
            filename: "#{Asset.generate_unique_secure_token}.#{base64_file_extension}"
          )

          @extracted_base64_images << tiny_image

          encoded_id = Base62.encode(tiny_image.id)

          sanitized_text.gsub!("#{base64_src}\"", "\" data-mce-token=\"#{encoded_id}\" alt=\"description-#{encoded_id}\"")
          sanitized_text.gsub!("#{base64_src}'", "' data-mce-token=\"#{encoded_id}\" alt=\"description-#{encoded_id}\"")
        end

        assign_attributes(object_field => sanitized_text)
      end
    end

    def ensure_extracted_image_object_references
      # for models that were not yet in database in time of image extraction
      # we need to update image references after creation

      @extracted_base64_images&.each do |image|
        next if image.object

        image.update(object: self)
      end
    end
  end

  def convert_to_base64(image)
    encoded_data = Base64.strict_encode64(image.download)
    "data:#{image.blob.content_type};base64,#{encoded_data}"
  rescue StandardError => e
    Rails.logger.error e.message
    "data:#{image.blob.content_type};base64,"
  end
  # rubocop:enable Metrics/BlockLength:
end
