class ReportElement < ActiveRecord::Base
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
  has_many :children, -> { order(:position) }, class_name: "ReportElement", foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "ReportElement"

  # References to various report entities
  belongs_to :project, inverse_of: :report_elements
  belongs_to :experiment, inverse_of: :report_elements
  belongs_to :my_module, inverse_of: :report_elements
  belongs_to :step, inverse_of: :report_elements
  belongs_to :result, inverse_of: :report_elements
  belongs_to :checklist, inverse_of: :report_elements
  belongs_to :asset, inverse_of: :report_elements
  belongs_to :table, inverse_of: :report_elements

  def has_children?
    children.length > 0
  end

  def result?
    result_asset? or result_table? or result_text?
  end

  def comments?
    step_comments? or result_comments?
  end

  # Get the referenced element (previously, element's type_of must be set)
  def element_reference
    if project_header? or project_activity? or project_samples?
      return project
    elsif experiment?
      return experiment
    elsif my_module? or my_module_activity? or my_module_samples?
      return my_module
    elsif step? or step_comments?
      return step
    elsif result_asset? or result_table? or result_text? or result_comments?
      return result
    elsif step_checklist?
      return checklist
    elsif step_asset?
      return asset
    elsif step_table?
      return table
    end
  end


  # Set the element reference (previously, element's type_of must be set)
  def set_element_reference(ref_id)
    if project_header? or project_activity? or project_samples?
      self.project_id = ref_id
    elsif experiment?
      self.experiment_id = ref_id
    elsif my_module? or my_module_activity? or my_module_samples?
      self.my_module_id = ref_id
    elsif step? or step_comments?
      self.step_id = ref_id
    elsif result_asset? or result_table? or result_text? or result_comments?
      self.result_id = ref_id
    elsif step_checklist?
      self.checklist_id = ref_id
    elsif step_asset?
      self.asset_id = ref_id
    elsif step_table?
      self.table_id = ref_id
    end
  end

  # removes element that are archived or deleted
  def clean_removed_or_archived_elements
    parent_model = ''
    %w(project experiment my_module step result checklist asset table)
      .each do |el|
      parent_model = el if send el
    end

    if parent_model == 'experiment'
      destroy unless send(parent_model).project == report.project
    elsif parent_model == 'step'
      destroy unless send(parent_model).completed
    else
      destroy unless (send(parent_model).active? rescue send(parent_model))
    end
  end

  private

  def has_one_of_referenced_elements
    num_of_refs = [
      project,
      experiment,
      my_module,
      step,
      result,
      checklist,
      asset,
      table
    ].count { |r| r.present? }
    if num_of_refs != 1
      errors.add(:base, "Report element must have exactly one element reference.")
    end
  end
end
