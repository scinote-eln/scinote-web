# frozen_string_literal: true

class StorageLocation < ApplicationRecord
  include Cloneable
  include Discard::Model
  ID_PREFIX = 'SL'
  include PrefixedIdModel

  default_scope -> { kept }

  has_one_attached :image

  belongs_to :team
  belongs_to :parent, class_name: 'StorageLocation', optional: true
  belongs_to :created_by, class_name: 'User'

  has_many :storage_location_repository_rows, inverse_of: :storage_location
  has_many :storage_locations, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :repository_rows, through: :storage_location_repository_row

  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  after_discard do
    StorageLocation.where(parent_id: id).find_each(&:discard)
    storage_location_repository_rows.each(&:discard)
  end

  def duplicate!
    ActiveRecord::Base.transaction do
      new_storage_location = dup
      new_storage_location.name = next_clone_name
      new_storage_location.save!
      copy_image(self, new_storage_location)
      recursive_duplicate(id, new_storage_location.id)
      new_storage_location
    rescue ActiveRecord::RecordInvalid
      false
    end
  end

  private

  def recursive_duplicate(old_parent_id = nil, new_parent_id = nil)
    StorageLocation.where(parent_id: old_parent_id).find_each do |child|
      new_child = child.dup
      new_child.parent_id = new_parent_id
      new_child.save!
      copy_image(child, new_child)
      recursive_duplicate(child.id, new_child.id)
    end
  end

  def copy_image(old_storage_location, new_storage_location)
    return unless old_storage_location.image.attached?

    old_blob = old_storage_location.image.blob
    old_blob.open do |tmp_file|
      to_blob = ActiveStorage::Blob.create_and_upload!(
        io: tmp_file,
        filename: old_blob.filename,
        metadata: old_blob.metadata
      )
      new_storage_location.image.attach(to_blob)
    end
  end
end
