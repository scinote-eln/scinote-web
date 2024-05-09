# frozen_string_literal: true

class Tag < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, :color, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :color,
            presence: true,
            length: { maximum: Constants::COLOR_MAX_LENGTH }
  validates :project, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :project
  has_many :my_module_tags, inverse_of: :tag, dependent: :destroy
  has_many :my_modules, through: :my_module_tags, dependent: :destroy
end
