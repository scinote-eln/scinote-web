# frozen_string_literal: true

class TinyMceAsset < ApplicationRecord
  extend ProtocolsExporter
  extend MarvinJsActions
  include ActiveStorageConcerns

  attr_accessor :reference
  before_create :set_reference
  after_create :calculate_estimated_size, :self_destruct
  after_destroy :release_team_space

  belongs_to :team, inverse_of: :tiny_mce_assets, optional: true

  belongs_to :object, polymorphic: true,
                      optional: true,
                      inverse_of: :tiny_mce_assets

  has_one_attached :image

  validates :estimated_size, presence: true

  def self.update_images(object, images, current_user)
    images = JSON.parse(images)
    current_images = object.tiny_mce_assets.pluck(:id)
    images_to_delete = current_images.reject do |x|
      (images.include? Base62.encode(x))
    end
    images.each do |image|
      image_to_update = find_by(id: Base62.decode(image))
      next if image_to_update.object || image_to_update.team_id != Team.search_by_object(object).id

      image_to_update&.update(object: object, saved: true)
      create_create_marvinjs_activity(image_to_update, current_user)
    end

    where(id: images_to_delete).find_each do |image_to_delete|
      create_delete_marvinjs_activity(image_to_delete, current_user)
      image_to_delete.destroy
    end

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
      new_asset = obj.tiny_mce_assets.find_by(id: Base62.decode(asset_id))
      if new_asset&.image&.attached?
        tm_asset.attributes['src'].value = Rails.application.routes.url_helpers.url_for(new_asset.image)
        tm_asset['class'] = 'img-responsive'
      end
    end
    description.css('body').inner_html.to_s
  end

  def file_name
    return '' unless image.attached?

    image.blob&.filename&.sanitized
  end

  def file_size
    return 0 unless image.attached?

    image.blob&.byte_size
  end

  def content_type
    return '' unless image.attached?

    image&.blob&.content_type
  end

  def preview
    image.variant(resize_to_limit: Constants::LARGE_PIC_FORMAT)
  end

  def self.delete_unsaved_image(id)
    asset = find_by(id: id)
    asset.destroy if asset && !asset.saved
  end

  def self.update_estimated_size(id)
    asset = find_by(id: id)
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

      asset = find_by(id: token)
      # impor flag only for import from file cases, because we don't have image in DB
      unless asset || import
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
        extension = tiny_mce_asset.image.blob.filename.extension
        asset_file_name = if extension.empty?
                            "rte-#{asset_guid}"
                          else
                            "rte-#{asset_guid}.#{tiny_mce_asset.image.blob.filename.extension}"
                          end
        ostream.put_next_entry("#{dir}/#{asset_file_name}")
        ostream.print(tiny_mce_asset.image.download)
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
      duplicate_file(tiny_img_clone)
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

  def blob
    image&.blob
  end

  def duplicate_file(to_asset)
    return unless image.attached?

    raise ArgumentError, 'Destination TinyMce asset should be persisted first!' unless to_asset.persisted?

    image.blob.open do |tmp_file|
      to_blob = ActiveStorage::Blob.create_after_upload!(io: tmp_file, filename: blob.filename, metadata: blob.metadata)
      to_asset.image.attach(to_blob)
    end
    TinyMceAsset.update_estimated_size(to_asset.id)
  end

  private

  def self_destruct
    TinyMceAsset.delay(queue: :assets, run_at: 1.day.from_now).delete_unsaved_image(id)
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
