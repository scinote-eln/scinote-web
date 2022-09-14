# frozen_string_literal: true

module Api
  module V1
    class StepOrderableElementSerializer < ActiveModel::Serializer
      attributes :position, :element

      def element
        case object.orderable_type
        when 'Checklist'
          ChecklistSerializer.new(object.orderable).as_json
        when 'StepTable'
          TableSerializer.new(object.orderable.table).as_json
        when 'StepText'
          StepTextSerializer.new(object.orderable).as_json
        end
      end
    end
  end
end
