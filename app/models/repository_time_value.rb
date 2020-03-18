# frozen_string_literal: true

class RepositoryTimeValue < RepositoryDateTimeValueBase
  PRELOAD_INCLUDE = :repository_time_value

  def data_changed?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.min != data.min || new_time.hour != data.hour
  end

  def formatted
    super(:time)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  def self.import_from_text(text, attributes, _options = {})
    time_format = '%H:%M'
    new(attributes.merge(data: DateTime.strptime(text, time_format).strftime(time_format)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
