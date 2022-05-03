# frozen_string_literal: true

class StepOrderableElementSerializer < ActiveModel::Serializer
  attributes :position, :element, :orderable_type

  def element
    case object.orderable_type
    when 'Checklist'
      ChecklistSerializer.new(object.orderable).as_json
    when 'StepTable'
      StepTableSerializer.new(object.orderable.table).as_json
    when 'StepText'
      StepTextSerializer.new(object.orderable).as_json
    end
  end
end
