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
  validate :has_one_of_referenced_elements

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
  belongs_to :repository, inverse_of: :report_elements, optional: true

  def has_children?
    children.length > 0
  end

  def result?
    result_asset? or result_table? or result_text?
  end

  def comments?
    step_comments? or result_comments?
  end

  # Get the referenced elements (previously, element's type_of must be set)
  def element_references
    ReportExtends::ELEMENT_REFERENCES.each do |el_ref|
      if el_ref.check(self)
        return el_ref.elements.map { |el| eval(el.gsub('_id', '')) }
      end
    end
  end

  # Set the element references (previously, element's type_of must be set)
  def set_element_references(ref_ids)
    ReportExtends::SET_ELEMENT_REFERENCES_LIST.each do |el_ref|
      check = el_ref.check(self)
      next unless check
      el_ref.elements.each do |element|
        public_send("#{element}=", ref_ids[element])
      end
      break
    end
  end

  # removes element that are archived or deleted
  def clean_removed_or_archived_elements
    parent_model = ''
    %w(project
       experiment
       my_module
       step
       result
       checklist
       asset
       table
       repository)
      .each do |el|
      parent_model = el if send el
    end

    if parent_model == 'experiment'
      destroy unless send(parent_model).project == report.project
    else
      destroy unless (send(parent_model).active? rescue send(parent_model))
    end
  end

  private

  def has_one_of_referenced_elements
    element_references.each do |el|
      next unless el.nil?
      errors.add(:base,
                 'Report element doesn\'t have correct element references.')
      break
    end
  end
end
