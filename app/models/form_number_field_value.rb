# frozen_string_literal: true

class FormNumberFieldValue < FormFieldValue
  include ActionView::Helpers::NumberHelper

  def value=(val)
    self.unit = form_field.data['unit']

    if val.is_a?(Array)
      self.number = val[0]
      self.number_to = val[1]
    else
      self.number = val
    end
  end

  def value
    if range?
      [
        cast_number(number),
        cast_number(number_to)
      ]
    else
      cast_number(number)
    end
  end

  def range?
    number_to.present?
  end

  def formatted
    number_with_unit = "#{cast_number(number)} #{unit}"
    range? ? "#{number_with_unit} - #{cast_number(number_to)} #{unit}" : number_with_unit
  end

  def value_in_range?
    return true if number.nil?

    validation_params = form_field.data.dig('validations', 'response_validation')

    return true unless validation_params && validation_params['enabled']

    min_value = validation_params['min']
    max_value = validation_params['max']

    !((min_value.present? && min_value > number) || (max_value.present? && max_value < number))
  end

  private

  def cast_number(big_decimal_number)
    return big_decimal_number.to_i if big_decimal_number.frac.zero?

    big_decimal_number
  end
end
