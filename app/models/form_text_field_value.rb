# frozen_string_literal: true

class FormTextFieldValue < FormFieldValue
  def value=(val)
    self.text = val
  end

  def value
    text
  end
end
