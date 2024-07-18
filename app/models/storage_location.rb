# frozen_string_literal: true

class StorageLocation < ApplicationRecord
  include Discard::Model
  ID_PREFIX = 'SL'
  include PrefixedIdModel

  default_scope -> { kept }

  has_one_attached :image

  belongs_to :team
  belongs_to :parent, class_name: 'StorageLocation', optional: true
  belongs_to :created_by, class_name: 'User'

  has_many :storage_location_repository_rows, inverse_of: :storage_location, dependent: :destroy
  has_many :storage_locations, foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :repository_rows, through: :storage_location_repository_row

  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  after_discard do
    StorageLocation.where(parent_id: id).find_each(&:discard)
    storage_location_repository_rows.each(&:discard)
  end
end
