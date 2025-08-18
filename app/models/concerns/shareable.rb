# frozen_string_literal: true

module Shareable
  extend ActiveSupport::Concern

  included do
    has_many :team_shared_objects, as: :shared_object, dependent: :destroy
    has_many :teams_shared_with, through: :team_shared_objects, source: :team, dependent: :destroy

    if column_names.include? 'permission_level'
      enum permission_level: Extends::SHARED_OBJECTS_PERMISSION_LEVELS
      define_method :globally_shareable? do
        true
      end
    else
      # If model does not include the permission_level column for global sharing,
      # all related methods should just return false
      Extends::SHARED_OBJECTS_PERMISSION_LEVELS.each do |level|
        define_method "#{level[0]}?" do
          level[0] == :not_shared
        end

        define_method :globally_shareable? do
          false
        end
      end
    end

    scope :shared_with_team, lambda { |team|
      directly_shared = joins(:team_shared_objects, :team).where(team_shared_objects: { team: team })
      globally_shared =
        if column_names.include?('permission_level')
          where(
            permission_level: [
              Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_read],
              Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_write]
            ]
          )
        else
          none
        end
      where(id: directly_shared.select(:id)).or(where(id: globally_shared.select(:id)))
    }
  rescue ActiveRecord::NoDatabaseError,
         ActiveRecord::ConnectionNotEstablished,
         ActiveRecord::StatementInvalid,
         PG::ConnectionBad

    Rails.logger.info('Not connected to database, skipping sharable model initialization.')
  end

  def can_manage_shared?(user)
    globally_shared? ||
      (shared_with?(user.current_team) && user.current_team.permission_granted?(user, TeamPermissions::MANAGE))
  end

  def shareable_write?
    true
  end

  def private_shared_with?(team)
    team_shared_objects.exists?(team: team)
  end

  def private_shared_with_read?(team)
    team_shared_objects.exists?(team: team, permission_level: :shared_read)
  end

  def private_shared_with_write?(team)
    team_shared_objects.exists?(team: team, permission_level: :shared_write)
  end

  def i_shared?(team)
    shared_with_anybody? && self.team == team
  end

  def globally_shared?
    shared_read? || shared_write?
  end

  def shared_with_anybody?
    (!not_shared? || team_shared_objects.any?)
  end

  def shared_with?(team)
    return false if self.team == team

    !not_shared? || private_shared_with?(team)
  end

  def shared_with_write?(team)
    return false if self.team == team

    shared_write? || private_shared_with_write?(team)
  end

  def shared_with_read?(team)
    return false if self.team == team

    shared_read? || team_shared_objects.exists?(team: team, permission_level: :shared_read)
  end

  def demote_all_sharing_assignments_to_viewer!(for_team: nil)
    # take into account special roles with no read permission, and do not upgrade them to viewer
    read_permission = "#{self.class.permission_class}Permissions".constantize::READ

    teams = for_team ? Team.where(id: for_team.id).where.not(id: team.id) : Team.where.not(id: team.id)

    [user_assignments, user_group_assignments, team_assignments].each do |assignments|
      assignments.joins(:user_role)
                 .where(team_id: teams.select(:id))
                 .where(['user_roles.permissions @> ARRAY[?]::varchar[]', [read_permission]])
                 .update!(user_role: UserRole.find_predefined_viewer_role)
    end
  end

  def destroy_all_sharing_assignments!(for_team: nil)
    teams = for_team ? Team.where(id: for_team.id).where.not(id: team.id) : Team.where.not(id: team.id)

    user_assignments.where(team_id: teams.select(:id)).destroy_all
    user_group_assignments.where(team_id: teams.select(:id)).destroy_all
    team_assignments.where(team_id: teams.select(:id)).destroy_all
  end
end
