# frozen_string_literal: true

class RepositoryDateValue < RepositoryDateTimeValueBase
  PRELOAD_INCLUDE = :repository_date_value

  def data_changed?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.to_date != data.to_date
  end

  def formatted
    super(:full_date)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  def self.import_from_text(text, attributes, options = {})
    date_format = (options.dig(:user, :settings, :date_format) || Constants::DEFAULT_DATE_FORMAT).gsub(/%-/, '%')
    new(attributes.merge(data: DateTime.strptime(text, date_format)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
