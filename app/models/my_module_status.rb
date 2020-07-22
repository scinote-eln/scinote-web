# frozen_string_literal: true

class MyModuleStatus < ApplicationRecord
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

  private

  def next_in_same_flow
    errors.add(:next_status, :different_flow) unless next_status.my_module_status_flow == my_module_status_flow
  end

  def previous_in_same_flow
    errors.add(:previous_status, :different_flow) unless previous_status.my_module_status_flow == my_module_status_flow
  end
end
