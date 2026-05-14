# frozen_string_literal: true

class StepOrderableElementSerializer < ActiveModel::Serializer
  type :step_orderable_elements
  attributes :position, :orderable, :orderable_type, :step_orderable_element_id

  def orderable
    case object
    when Checklist
      ChecklistSerializer.new(object, scope: { user: @instance_options[:user] }, include: :checklist_item).as_json
    when Table
      TableSerializer.new(object, scope: { user: @instance_options[:user] }).as_json
    when StepText
      StepTextSerializer.new(object, scope: { user: @instance_options[:user] }).as_json
    when FormResponse
      StepFormResponseSerializer.new(object, scope: { user: @instance_options[:user] }).as_json
    end
  end

  def step_orderable_element_id
    case object
    when StepText, FormResponse, Checklist
      object.step_orderable_element&.id
    when Table
      object.step_table&.step_orderable_element&.id
    end
  end

  def position
    case object
    when StepText, FormResponse, Checklist
      object.step_orderable_element&.position
    when Table
      object.step_table&.step_orderable_element&.position
    end
  end

  def orderable_type
    object.class.name
  end
end
