# frozen_string_literal: true

class FormField < ApplicationRecord
  include Cloneable
  include SearchableModel

  SEARCHABLE_ATTRIBUTES = ['form_fields.name', 'form_fields.description'].freeze

  belongs_to :form
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
  has_many :form_field_values, dependent: :destroy

  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :position, presence: true, uniqueness: { scope: :form }

  acts_as_list scope: :form, top_of_list: 0, sequential_updates: true

  def parent
    form
  end

  def duplicate!(user = nil)
    new_form_field = dup
    new_form_field.name = next_clone_name
    new_form_field.created_by = user || created_by
    new_form_field.position = form.form_fields.size
    new_form_field.save!

    new_form_field.with_lock do
      new_form_field.insert_at(position + 1)
    end

    new_form_field
  end
end
