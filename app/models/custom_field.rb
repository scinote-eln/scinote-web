class CustomField < ActiveRecord::Base
  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :organization, case_sensitive: true },
            exclusion: { in: ['Assigned', 'Sample name', 'Sample type',
                              'Sample group', 'Added on', 'Added by'] }
  validates :user, :organization, presence: true

  belongs_to :user, inverse_of: :custom_fields
  belongs_to :organization, inverse_of: :custom_fields
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User'
  has_many :sample_custom_fields, inverse_of: :custom_field

  after_create :update_samples_table_state

  def update_samples_table_state
    SamplesTable.update_samples_table_state(self)
  end
end
