# frozen_string_literal: true

class StepOrderableElementSerializer < ActiveModel::Serializer
  attributes :position, :element, :orderable_type

  def element
    case object.orderable_type
    when 'Checklist'
      ChecklistSerializer
    when 'StepTable'
      StepTableSerializer
    when 'StepText'
      StepTextSerializer
    end
  end
end
