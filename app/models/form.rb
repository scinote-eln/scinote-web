# frozen_string_literal: true

class Form < ApplicationRecord
  include ArchivableModel

  belongs_to :team
  belongs_to :parent, class_name: 'Form', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
  belongs_to :published_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true

  has_many :form_fields, inverse_of: :form, dependent: :destroy

  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::NAME_MAX_LENGTH }
end
