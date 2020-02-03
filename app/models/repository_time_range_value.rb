# frozen_string_literal: true

class RepositoryTimeRangeValue < RepositoryDateTimeRangeValueBase
  PRELOAD_INCLUDE = :repository_time_range_value

  def data_changed?(new_data)
    data = JSON.parse(new_data).symbolize_keys

    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.hour != start_time.hour || et.hour != end_time.hour || st.min != start_time.min || et.min != end_time.min
  end

  def formatted
    super(:time)
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
