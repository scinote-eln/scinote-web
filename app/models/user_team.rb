# frozen_string_literal: true

class UserTeam < ApplicationRecord
  enum role: { guest: 0, normal_user: 1, admin: 2 }

  validates :role, :user, :team, presence: true

  belongs_to :user, inverse_of: :user_teams, touch: true
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User', optional: true
  belongs_to :team, inverse_of: :user_teams

  after_create :assign_user_to_visible_projects
  before_destroy :destroy_associations

  def role_str
    I18n.t("user_teams.enums.role.#{role}")
  end


  def destroy_associations
    # Destroy the user from all team's projects
    team.projects.each do |project|
      up2 = (project.user_projects.select { |up| up.user == self.user }).first
      if up2.present?
        up2.destroy
      end
    end
    # destroy all assignments
    UserAssignments::RemoveUserAssignmentJob.perform_now(user, team)
  end

  # returns user_teams where the user is in team
  def self.user_in_team(user, team)
    where(user: user, team: team)
  end

  def destroy(new_owner)
    return super() unless new_owner
    # If any project of the team has the sole owner and that
    # owner is the user to be removed from the team, then we must
    # create a new owner of the project (the provided user).
    team.projects.find_each do |project|
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
    # to the departing user and belong to this team.
    p_ids = user.added_protocols.where(team: team).pluck(:id)
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

    # Make new owner author of all inventory items that were added
    # by departing user and belong to this team.
    RepositoryRow.change_owner(team, user, new_owner)

    super()
  end

  private

  def assign_user_to_visible_projects
    team.projects.visible.each do |project|
      UserAssignments::GroupAssignmentJob.perform_later(
        team,
        project,
        assigned_by
      )
    end
  end
end
