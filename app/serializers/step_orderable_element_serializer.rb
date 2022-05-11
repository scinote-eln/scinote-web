# frozen_string_literal: true

class StepOrderableElementSerializer < ActiveModel::Serializer
  attributes :position, :orderable, :orderable_type

  def orderable
    case object.orderable_type
    when 'Checklist'
      ChecklistSerializer.new(object.orderable).as_json
    when 'StepTable'
      TableSerializer.new(object.orderable.table).as_json
    when 'StepText'
      StepTextSerializer.new(object.orderable, scope: { user: @instance_options[:user] }).as_json
    end
  end
end
