# frozen_string_literal: true

class MyModuleStatusFlow < ApplicationRecord
  enum visibility: { global: 0, in_team: 1 }

  has_many :my_module_statuses, dependent: :destroy
  belongs_to :team, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true

  validates :visibility, presence: true
  validates :team, presence: true, if: :in_team?
  validates :name, uniqueness: { scope: :team_id, case_sensitive: false }, if: :in_team?
  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }

  def initial_status
    my_module_statuses.find_by(previous_status: nil)
  end

  def final_status
    my_module_statuses.find_by(next_status: nil)
  end
end
