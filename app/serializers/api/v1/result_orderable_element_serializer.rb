# frozen_string_literal: true

module Api
  module V1
    class ResultOrderableElementSerializer < ActiveModel::Serializer
      attributes :position, :orderable, :orderable_type

      def orderable
        case object.orderable_type
        when 'ResultTable'
          ResultTableSerializer.new(object.orderable, scope: { user: @instance_options[:user] }).as_json
        when 'ResultText'
          ResultTextSerializer.new(object.orderable, scope: { user: @instance_options[:user] }).as_json
        end
      end
    end
  end
end
