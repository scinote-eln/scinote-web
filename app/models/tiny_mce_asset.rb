# frozen_string_literal: true

class TinyMceAsset < ApplicationRecord
  extend ProtocolsExporter
  attr_accessor :reference
  before_create :set_reference, optional: true
  after_create :calculate_estimated_size, :self_destruct
  after_destroy :release_team_space

  belongs_to :team, inverse_of: :tiny_mce_assets, optional: true
  belongs_to :step, inverse_of: :tiny_mce_assets, touch: true, optional: true
  belongs_to :result_text,
             inverse_of: :tiny_mce_assets,
             touch: true,
             optional: true

  belongs_to :object, polymorphic: true,
                      optional: true,
                      inverse_of: :tiny_mce_assets

  has_one_attached :image

  # has_attached_file :image,
  #                   styles: { large: [Constants::LARGE_PIC_FORMAT, :jpg] },
  #                   convert_options: { large: '-quality 100 -strip' }

  # validates_attachment_content_type :image,
  #                                   content_type: %r{^image/#{ Regexp.union(
  #                                     Constants::WHITELISTED_IMAGE_TYPES
  #                                   ) }}
  # validates_attachment :image,
  #                      presence: true,
  #                      size: {
  #                        less_than: Rails.configuration.x\
  #                                        .file_max_size_mb.megabytes
  #                      }
  validates :estimated_size, presence: true

  def self.update_images(object, images)
    images = JSON.parse(images)
    current_images = object.tiny_mce_assets.pluck(:id)
    images_to_delete = current_images.reject do |x|
      (images.include? Base62.encode(x))
    end
    images.each do |image|
      image_to_update = find_by_id(Base62.decode(image))
      image_to_update&.update(object: object, saved: true) unless image_to_update.object
    end
    where(id: images_to_delete).destroy_all

    object.delay(queue: :assets).copy_unknown_tiny_mce_images
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def self.generate_url(description, obj = nil)
    # Check tinymce for old format
    description = update_old_tinymce(description, obj)

    description = Nokogiri::HTML(description)
    tm_assets = description.css('img[data-mce-token]')
    tm_assets.each do |tm_asset|
      asset_id = tm_asset.attr('data-mce-token')
      new_asset = obj.tiny_mce_assets.find_by_id(Base62.decode(asset_id))
      if new_asset
        tm_asset.attributes['src'].value = Rails.application.routes.url_helpers.url_for(new_asset.image)
        tm_asset['class'] = 'img-responsive'
      end
    end
    description.css('body').inner_html.to_s
  end

  def file_name
    return '' unless image.attached?

    image.blob&.filename&.to_s
  end

  def file_size
    return 0 unless image.attached?

    image.blob&.byte_size
  end

  def content_type
    image&.blob&.content_type
  end

  def file_size
    image&.blob&.byte_size
  end

  def preview
    image.variant(resize: Constants::LARGE_PIC_FORMAT)
  end

  def self.delete_unsaved_image(id)
    asset = find_by_id(id)
    asset.destroy if asset && !asset.saved
  end

  def self.update_estimated_size(id)
    asset = find_by_id(id)
    return unless asset&.image&.attached?

    size = asset.image.blob.byte_size
    return if size.blank?

    e_size = size * Constants::ASSET_ESTIMATED_SIZE_FACTOR
    asset.update(estimated_size: e_size)
    Rails.logger.info "Asset #{id}: Estimated size successfully calculated"
    # update team space taken
    asset.team.take_space(e_size)
    asset.team.save
  end

  def self.update_old_tinymce(description, obj = nil)
    return description unless description

    description.scan(/\[~tiny_mce_id:(\w+)\]/).flatten.each do |token|
      old_format = /\[~tiny_mce_id:#{token}\]/
      new_format = "<img src=\"\" class=\"img-responsive\" data-mce-token=\"#{Base62.encode(token.to_i)}\"/>"

      asset = find_by_id(token)
      unless asset
        # remove tag if asset deleted
        description.sub!(old_format, '')
        next
      end

      # If object (step or result text) don't have direct assciation to tinyMCE image, we need copy it.
      asset.clone_tinymce_asset(obj) if obj && obj != asset.object

      description.sub!(old_format, new_format)
    end
    description
  end

  def self.save_to_eln(ostream, dir)
    if exists?
      order(:id).each do |tiny_mce_asset|
        asset_guid = get_guid(tiny_mce_asset.id)
        asset_file_name = "rte-#{asset_guid.to_s + File.extname(tiny_mce_asset.image.filename.to_s)}"
        ostream.put_next_entry("#{dir}/#{asset_file_name}")
        ostream.print(tiny_mce_asset.image.download)
        input_file.close
      end
    end
    ostream
  end

  def clone_tinymce_asset(obj)
    begin
      # It will trigger only for Step or ResultText
      team_id = if obj.class.name == 'Step'
                  obj.protocol.team_id
                else
                  obj.result.my_module.protocol.team_id
                end
    rescue StandardError => e
      Rails.logger.error e.message
      team_id = nil
    end

    return false unless team_id

    tiny_img_clone = TinyMceAsset.new(
      estimated_size: estimated_size,
      object: obj,
      team_id: team_id
    )

    tiny_img_clone.transaction do
      tiny_img_clone.save!
      tiny_img_clone.image.attach(io: image.download, filename: image.filename.to_s)
    end

    return false unless tiny_img_clone.persisted?

    obj.tiny_mce_assets << tiny_img_clone
    # Prepare array of image to update
    cloned_img_ids = [[id, tiny_img_clone.id]]

    obj_field = Extends::RICH_TEXT_FIELD_MAPPINGS[obj.class.name]

    # Update description with new format
    obj.update(obj_field => TinyMceAsset.update_old_tinymce(obj[obj_field]))

    # reassign images
    obj.reassign_tiny_mce_image_references(cloned_img_ids)
  end

  private

  def self_destruct
    TinyMceAsset.delay(queue: :assets, run_at: 1.days.from_now).delete_unsaved_image(id)
  end

  def calculate_estimated_size
    TinyMceAsset.delay(queue: :assets, run_at: 5.minutes.from_now).update_estimated_size(id)
  end

  def release_team_space
    team.release_space(estimated_size)
    team.save
  end

  def set_reference
    obj_type = "#{@reference.class.to_s.underscore}=".to_sym
    public_send(obj_type, @reference) if @reference
  end
end
