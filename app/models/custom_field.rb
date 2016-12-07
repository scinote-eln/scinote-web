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

  def self.create(opt)
    user = opt[:user]
    org = opt[:organization]
    samples_table = SamplesTable.where(user: user,
                                       organization: org)
    org_status = samples_table.first['status']
    index = org_status['columns'].count
    org_status['columns'][index] = { 'visible' => true,
                                     'search' => { 'search' => '',
                                                   'smart' => true,
                                                   'regex' => false,
                                                   'caseInsensitive' => true } }
    org_status['ColReorder'] << index
    samples_table.first.update(status: org_status)
    super(opt)
  end
end
