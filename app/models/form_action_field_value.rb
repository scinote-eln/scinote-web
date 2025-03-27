# frozen_string_literal: true

class FormActionFieldValue < FormFieldValue
  def value=(val)
    self.flag = val
  end

  def value
    flag
  end

  def formatted
    flag ? I18n.t('forms.export.values.completed') : I18n.t('forms.export.values.not_completed')
  end
end
