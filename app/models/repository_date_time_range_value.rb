# frozen_string_literal: true

class RepositoryDateTimeRangeValue < RepositoryDateTimeRangeValueBase
  PRELOAD_INCLUDE = :repository_date_time_range_value

  def data_changed?(new_data)
    data = JSON.parse(new_data).symbolize_keys
    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.to_i != start_time.to_i || et.to_i != end_time.to_i
  end

  def formatted
    super(:full_with_comma)
  end

  def self.new_with_payload(payload, attributes)
    data = JSON.parse(payload).symbolize_keys

    value = new(attributes)
    value.start_time = Time.zone.parse(data[:start_time])
    value.end_time = Time.zone.parse(data[:end_time])
    value
  end

  alias export_formatted formatted
end
