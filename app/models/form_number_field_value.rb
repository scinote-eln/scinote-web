# frozen_string_literal: true

class FormNumberFieldValue < FormFieldValue
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
    range? ? [number, number_to] : number
  end

  def range?
    number_to.present?
  end

  def formatted
    number_with_unit = "#{number} #{unit}"
    range? ? "#{number_with_unit} - #{number_to} #{unit}" : number_with_unit
  end

  def value_in_range?
    return true if number.nil?

    validation_params = form_field.data.dig('validations', 'response_validation')

    return true unless validation_params && validation_params['enabled']

    min_value = validation_params['min']
    max_value = validation_params['max']

    !((min_value.present? && min_value > number) || (max_value.present? && max_value < number))
  end
end
