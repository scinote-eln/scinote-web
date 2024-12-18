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
end
