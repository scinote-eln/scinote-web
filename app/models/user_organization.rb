class UserOrganization < ActiveRecord::Base
  enum role: { guest: 0, normal_user: 1, admin: 2 }

  validates :role, presence: true
  validates :user, presence: true
  validates :organization, presence: true

  belongs_to :user, inverse_of: :user_organizations
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User'
  belongs_to :organization, inverse_of: :user_organizations

  before_destroy :destroy_associations
  after_create :create_samples_table_state

  def role_str
    I18n.t("user_organizations.enums.role.#{role.to_s}")
  end

  def create_samples_table_state
    SamplesTable.create_samples_table_state(self)
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

  # returns user_organizations where the user is in org
  def self.user_in_organization(user, organization)
    where(user: user, organization: organization)
  end

  def destroy(new_owner)
    # If any project of the organization has the sole owner and that
    # owner is the user to be removed from the organization, then we must
    # create a new owner of the project (the provided user).
    organization.projects.find_each do |project|
      owners = project.user_projects.where(role: 0)
      if owners.count == 1 && owners.first.user == user
        if project.users.exists?(new_owner.id)
          # If the new owner is already assigned onto project,
          # update its role
          project.user_projects.find_by(user: new_owner).update(role: 0)
        else
          # Else, create a new association
          UserProject.create(
            user: new_owner,
            project: project,
            role: 0,
            assigned_by: user
          )
        end
      end
    end

    # Also, make new owner author of all protocols that belong
    # to the departing user.
    p_ids = user.added_protocols.pluck(:id)
    Protocol.find(p_ids).each do |protocol|
      protocol.record_timestamps = false
      protocol.added_by = new_owner
      if protocol.archived_by != nil
        protocol.archived_by = new_owner
      end
      if protocol.restored_by != nil
        protocol.restored_by = new_owner
      end
      protocol.save
    end

    super()
  end

end
