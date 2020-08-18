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
    my_module_statuses.left_outer_joins(:next_status).find_by('next_statuses_my_module_statuses.id': nil)
  end

  def self.ensure_default
    return if MyModuleStatusFlow.global.any?

    status_flow = MyModuleStatusFlow.create!(name: Extends::DEFAULT_FLOW_NAME, visibility: :global)
    prev_id = nil
    Extends::DEFAULT_FLOW_STATUSES.each do |status|
      new_status = MyModuleStatus.create!(my_module_status_flow: status_flow,
                                name: status[:name],
                                color: status[:color],
                                previous_status_id: prev_id)
      prev_id = new_status.id

      status[:conditions]&.each { |condition| condition.constantize.create!(my_module_status: new_status) }
      status[:implications]&.each { |implication| implication.constantize.create!(my_module_status: new_status) }
      status[:consequences]&.each { |consequence| consequence.constantize.create!(my_module_status: new_status) }
    end
  end
end
