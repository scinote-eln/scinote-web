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

  def formatted
    if form_field.data['time']
      range? ? [datetime&.utc, datetime_to&.utc].join(' - ') : datetime&.utc.to_s
    else
      range? ? [datetime&.to_date, datetime_to&.to_date].join(' - ') : datetime&.to_date.to_s
    end
  end

  def formatted_localize
    format = form_field.data['time'] ? :full : :full_date
    from = datetime ? I18n.l(datetime, format: format) : ''
    to = datetime_to ? I18n.l(datetime_to, format: format) : ''

    range? ? [from, to].join(' - ') : from
  end
end
