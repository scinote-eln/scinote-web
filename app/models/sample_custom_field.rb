class SampleCustomField < ActiveRecord::Base
  include InputSanitizeHelper

  auto_strip_attributes :value, nullify: false
  before_validation :sanitize_fields, on: [:create, :update]
  validates :value,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :custom_field, :sample, presence: true

  belongs_to :custom_field, inverse_of: :sample_custom_fields
  belongs_to :sample, inverse_of: :sample_custom_fields

  private

  def sanitize_fields
    self.value = escape_input(value)
  end
end
