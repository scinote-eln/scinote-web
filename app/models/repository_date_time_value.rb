# frozen_string_literal: true

class RepositoryDateTimeValue < RepositoryDateTimeValueBase
  PRELOAD_INCLUDE = :repository_date_time_value

  def data_changed?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.to_i != data.to_i
  end

  def formatted
    super(:full_with_comma)
  end

  def export_formatted
    I18n.l(data, format: :full)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  def self.import_from_text(text, attributes, options = {})
    date_format = (options.dig(:user, :settings, :date_format) || Constants::DEFAULT_DATE_FORMAT).gsub(/%-/, '%') + ' %H:%M'
    Time.zone = options.dig(:user, :settings, :time_zone) || 'UTC'
    new(attributes.merge(data: Time.zone.strptime(text, date_format)))
  rescue ArgumentError
    nil
  end
end
