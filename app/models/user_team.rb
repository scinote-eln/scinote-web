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
    user.user_projects.joins(:project).where(project: team.projects).destroy_all
    # destroy all assignments
    UserAssignments::RemoveUserAssignmentJob.perform_now(user, team)
  end

  # returns user_teams where the user is in team
  def self.user_in_team(user, team)
    where(user: user, team: team)
  end

  def destroy(new_owner)
    return super() unless new_owner

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
      UserAssignments::ProjectGroupAssignmentJob.perform_later(
        team,
        project,
        assigned_by
      )
    end
  end
end
