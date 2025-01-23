# frozen_string_literal: true

class FormSingleChoiceFieldValue < FormFieldValue
  def value=(val)
    self.text = val
  end

  def value
    text
  end
end
