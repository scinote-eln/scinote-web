# frozen_string_literal: true

class TeamRepository < ApplicationRecord
  enum permission_level: Extends::SHARED_INVENTORIES_PERMISSION_LEVELS

  belongs_to :team
  belongs_to :repository

  validates :permission_level, presence: true
  validates :repository, uniqueness: { scope: :team_id }
  validates :team_id, inclusion: { in: proc { |object| Team.pluck(:id) - [object.repository&.team&.id] } }
end
