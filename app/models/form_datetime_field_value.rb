# frozen_string_literal: true

class FormDatetimeFieldValue < FormFieldValue
  def value=(val)
    if val.is_a?(Array)
      self.datetime = val[0]
      self.datetime_to = val[1]
    else
      self.datetime = val
    end
  end

  def value
    range? ? [datetime, datetime_to] : datetime
  end

  def range?
    datetime_to.present?
  end
end
