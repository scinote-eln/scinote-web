# frozen_string_literal: true

class FormDatetimeFieldValue < FormFieldValue
  def value=(val)
    start_attr, end_attr = form_field.data['time'] ? [:datetime, :datetime_to] : [:date, :date_to]

    if val.is_a?(Array)
      self[start_attr] = val[0]
      self[end_attr]   = val[1]
    else
      self[start_attr] = val
    end
  end

  def value
    if form_field.data['time']
      range? ? [datetime, datetime_to] : datetime
    else
      range? ? [date, date_to] : date
    end
  end

  def range?
    form_field.data['time'] ? datetime_to.present? : date_to.present?
  end

  def formatted
    if form_field.data['time']
      range? ? [datetime&.utc, datetime_to&.utc].join(' - ') : datetime&.utc.to_s
    else
      range? ? [date, date_to].join(' - ') : date.to_s
    end
  end

  def formatted_localize
    if form_field.data['time']
      from = datetime ? I18n.l(datetime, format: :full) : ''
      to = datetime_to ? I18n.l(datetime_to, format: :full) : ''
    else
      from = date ? I18n.l(date, format: :full_date) : ''
      to = date_to ? I18n.l(date_to, format: :full_date) : ''
    end

    range? ? [from, to].join(' - ') : from
  end
end
