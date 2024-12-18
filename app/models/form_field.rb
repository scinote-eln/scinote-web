# frozen_string_literal: true

class FormField < ApplicationRecord
  belongs_to :form
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
  has_many :form_field_values, dependent: :destroy

  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :position, presence: true, uniqueness: { scope: :form }

  acts_as_list scope: :form, top_of_list: 0, sequential_updates: true
end
