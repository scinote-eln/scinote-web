# frozen_string_literal: true

class ResultOrderableElementSerializer < ActiveModel::Serializer
  type :result_orderable_elements
  attributes :position, :orderable, :orderable_type

  def orderable
    case object
    when Table
      ResultTableSerializer.new(object, scope: { user: @instance_options[:user] }).as_json
    when ResultText
      ResultTextSerializer.new(object, scope: { user: @instance_options[:user] }).as_json
    end
  end

  def position
    case object
    when ResultText
      object.result_orderable_element&.position
    when Table
      object.result_table&.result_orderable_element&.position
    end
  end

  def orderable_type
    object.class.name
  end
end
