# frozen_string_literal: true

class TeamAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :team
  belongs_to :user_role
  belongs_to :assigned_by, class_name: 'User'
  has_many :users, through: :team

  enum assigned: { automatically: 0, manually: 1 }, _suffix: true

  validates :team, uniqueness: { scope: :assignable }
end
