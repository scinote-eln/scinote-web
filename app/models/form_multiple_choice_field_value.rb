# frozen_string_literal: true

class FormMultipleChoiceFieldValue < FormFieldValue
  def value=(val)
    self.selection = val
  end

  def value
    selection
  end

  def formatted
    value.join('|')
  end
end
