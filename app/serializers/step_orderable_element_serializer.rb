# frozen_string_literal: true

class StepOrderableElementSerializer < ActiveModel::Serializer
  attributes :position, :orderable, :orderable_type

  def orderable
    case object.orderable_type
    when 'Checklist'
      ChecklistSerializer.new(object.checklist, include: :checklist_item, **@instance_options).as_json
    when 'StepTable'
      TableSerializer.new(object.step_table.table, @instance_options).as_json
    when 'StepText'
      StepTextSerializer.new(object.step_text, @instance_options).as_json
    when 'FormResponse'
      StepFormResponseSerializer.new(object.step_form_response, @instance_options).as_json
    end
  end
end
