class MigrateOrganizationsStructure < ActiveRecord::Migration[4.2]
  def up
    # Update estimated size of all assets
    Asset.includes(:asset_text_datum).find_each do |asset|
      asset.update_estimated_size
      asset.update(file_present: true)
    end

    # Calculate teams' taken space
    Team.find_each do |team|
      team.calculate_space_taken
      team.save
    end

    # Finally, the trickiest task: Re-define teams
    demo_team = Team.find_by(name: "Demo team")
    if demo_team
      demo_team.user_teams.each do |uo|
        uo.destroy
      end
    end
    Team.find_each do |team|
      user = team.users.first
      team.update(created_by: user)
    end

    UserTeam.find_each do |uo|
      uo.update(role: 2)
    end
  end

  def down
    # We cannot re-assign users to demo team or re-update
    # their previous user-team roles

    # But we can remove created_by field from teams
    Team.find_each do |team|
      team.update(created_by: nil)
    end

    # Resetting calculated assets & teams' space
    # to 0 doesn't make much sense even when downgrading migration
  end
end
