# frozen_string_literal: true

class TeamRepository < ApplicationRecord
  enum permission_level: Extends::SHARED_INVENTORIES_PERMISSION_LEVELS

  belongs_to :team
  belongs_to :repository

  validates :permission_level, presence: true
  validates :repository, uniqueness: { scope: :team_id }
  validate :team_cannot_be_the_same

  private

  def team_cannot_be_the_same
    errors.add(:team_id, :same_team) if repository&.team_id == team_id
  end
end
