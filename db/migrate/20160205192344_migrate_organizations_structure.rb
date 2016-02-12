class MigrateOrganizationsStructure < ActiveRecord::Migration
  def up
    # Update estimated size of all assets
    Asset.includes(:asset_text_datum).find_each do |asset|
      asset.update_estimated_size
      asset.update(file_present: true)
    end

    # Calculate organizations' taken space
    Organization.find_each do |org|
      org.calculate_space_taken
      org.save
    end

    # Finally, the trickiest task: Re-define organizations
    demo_org = Organization.find_by(name: "Demo organization")
    if demo_org
      demo_org.user_organizations.each do |uo|
        uo.destroy
      end
    end
    Organization.find_each do |org|
      user = org.users.first
      org.update(created_by: user)
    end

    UserOrganization.find_each do |uo|
      uo.update(role: 2)
    end
  end

  def down
    # We cannot re-assign users to demo organization or re-update
    # their previous user-organization roles

    # But we can remove created_by field from organizations
    Organization.find_each do |org|
      org.update(created_by: nil)
    end

    # Resetting calculated assets & organizations' space
    # to 0 doesn't make much sense even when downgrading migration
  end
end
