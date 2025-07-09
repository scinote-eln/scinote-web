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

    scope :viewable_by_user, lambda { |user, teams = user.current_team|
      readable_ids = with_granted_permissions(user, "#{permission_class.name}Permissions::READ".constantize, teams).pluck(:id)
      shared_with_team_ids = joins(:team_shared_objects, :team).where(team_shared_objects: { team: teams }).pluck(:id)
      globally_shared_ids =
        if column_names.include?('permission_level')
          joins(:team).where(
            {
              permission_level: [
                Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_read],
                Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_write]
              ]
            }
          ).pluck(:id)
        else
          none.pluck(:id)
        end

      where(id: (readable_ids + shared_with_team_ids + globally_shared_ids).uniq)
    }
  rescue ActiveRecord::NoDatabaseError,
         ActiveRecord::ConnectionNotEstablished,
         ActiveRecord::StatementInvalid,
         PG::ConnectionBad

    Rails.logger.info('Not connected to database, skipping sharable model initialization.')
  end

  def shareable_write?
    true
  end

  def private_shared_with?(team)
    team_shared_objects.where(team: team).any?
  end

  def private_shared_with_write?(team)
    team_shared_objects.where(team: team, permission_level: :shared_write).any?
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

    shared_read? || team_shared_objects.where(team: team, permission_level: :shared_read).any?
  end
end
