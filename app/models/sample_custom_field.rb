# frozen_string_literal: true

class SampleCustomField < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :value, nullify: false
  validates :value, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :custom_field, :sample, presence: true

  belongs_to :custom_field, inverse_of: :sample_custom_fields
  belongs_to :sample, inverse_of: :sample_custom_fields
end
