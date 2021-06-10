# frozen_string_literal: true

class ReportElement < ApplicationRecord
  enum type_of: Extends::REPORT_ELEMENT_TYPES

  # This is only used by certain elements
  enum sort_order: {
    asc: 0,
    desc: 1
  }

  validates :position, presence: true
  validates :report, presence: true
  validates :type_of, presence: true

  belongs_to :report, inverse_of: :report_elements

  # Hierarchical structure representation
  has_many :children,
           -> { order(:position) },
           class_name: 'ReportElement',
           foreign_key: 'parent_id',
           dependent: :destroy
  belongs_to :parent, class_name: 'ReportElement', optional: true

  # References to various report entities
  belongs_to :project, inverse_of: :report_elements, optional: true
  belongs_to :experiment, inverse_of: :report_elements, optional: true
  belongs_to :my_module, inverse_of: :report_elements, optional: true
  belongs_to :step, inverse_of: :report_elements, optional: true
  belongs_to :result, inverse_of: :report_elements, optional: true
  belongs_to :checklist, inverse_of: :report_elements, optional: true
  belongs_to :asset, inverse_of: :report_elements, optional: true
  belongs_to :table, inverse_of: :report_elements, optional: true
  belongs_to :repository, inverse_of: :report_elements, optional: true, class_name: 'RepositoryBase'

  scope :active, -> { where(type_of: Extends::ACTIVE_REPORT_ELEMENTS) }
end
