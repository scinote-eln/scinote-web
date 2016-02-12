class SampleCustomField < ActiveRecord::Base
  validates :value,
    presence: true,
    length: { maximum: 100 }
  validates :custom_field, :sample, presence: true

  belongs_to :custom_field, inverse_of: :sample_custom_fields
  belongs_to :sample, inverse_of: :sample_custom_fields
end
