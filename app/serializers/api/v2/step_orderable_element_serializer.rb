# frozen_string_literal: true

module Api
  module V2
    class StepOrderableElementSerializer < ActiveModel::Serializer
      attributes :position, :element

      def element
        case object.orderable_type
        when 'Checklist'
          Api::V1::ChecklistSerializer.new(object.orderable).as_json
        when 'StepTable'
          Api::V1::TableSerializer.new(object.orderable.table).as_json
        when 'StepText'
          Api::V1::StepTextSerializer.new(object.orderable).as_json
        when 'FromResponse'
          Api::V2::FormResponseSerializer.new(object.orderable).as_json
        end
      end
    end
  end
end
