# frozen_string_literal: true

class MyModuleStatus < ApplicationRecord
  class MyModuleStatusTransitionError < StandardError
    attr_reader :error

    def initialize(error)
      @error = error
      super
    end
  end

  has_many :my_modules, dependent: :nullify
  has_many :my_module_status_conditions, dependent: :destroy
  has_many :my_module_status_consequences, dependent: :destroy
  has_many :my_module_status_implications, dependent: :destroy
  belongs_to :my_module_status_flow
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true
  has_one :next_status, class_name: 'MyModuleStatus',
                        foreign_key: 'previous_status_id',
                        inverse_of: :previous_status,
                        dependent: :nullify
  belongs_to :previous_status, class_name: 'MyModuleStatus', inverse_of: :next_status, optional: true

  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :color, presence: true
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :next_status, uniqueness: true, if: -> { next_status.present? }
  validates :previous_status, uniqueness: true, if: -> { previous_status.present? }
  validate :next_in_same_flow, if: -> { next_status.present? }
  validate :previous_in_same_flow, if: -> { previous_status.present? }

  def initial_status?
    my_module_status_flow.initial_status == self
  end

  def final_status?
    my_module_status_flow.final_status == self
  end

  def self.sort_by_position(order = :asc)
    ordered_statuses, statuses = all.to_a.partition { |i| i.previous_status_id.nil? }

    return [] if ordered_statuses.blank?

    until statuses.blank?
      next_element, statuses = statuses.partition { |i| ordered_statuses.last.id == i.previous_status_id }
      if next_element.blank?
        break
      else
        ordered_statuses.concat(next_element)
      end
    end
    ordered_statuses = ordered_statuses.reverse if order == :desc
    ordered_statuses
  end

  def conditions_errors(my_module)
    mm_copy = my_module.clone
    mm_copy.errors.clear

    my_module_status_conditions.each do |condition|
      condition.call(mm_copy)
    end

    mm_copy.errors.messages&.values&.flatten
  end

  def light_color?
    color == '#FFFFFF'
  end

  private

  def next_in_same_flow
    errors.add(:next_status, :different_flow) unless next_status.my_module_status_flow == my_module_status_flow
  end

  def previous_in_same_flow
    errors.add(:previous_status, :different_flow) unless previous_status.my_module_status_flow == my_module_status_flow
  end
end
