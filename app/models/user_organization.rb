class UserOrganization < ActiveRecord::Base
  enum role: { guest: 0, normal_user: 1, admin: 2 }

  validates :role, presence: true
  validates :user, presence: true
  validates :organization, presence: true

  belongs_to :user, inverse_of: :user_organizations
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :organization, inverse_of: :user_organizations

  before_destroy :destroy_associations

  def role_str
    I18n.t("user_organizations.enums.role.#{role.to_s}")
  end

  def destroy_associations
    # Destroy the user from all organization's projects
    organization.projects.each do |project|
      up2 = (project.user_projects.select { |up| up.user == self.user }).first
      if up2.present?
        up2.destroy
      end
    end
  end

end
