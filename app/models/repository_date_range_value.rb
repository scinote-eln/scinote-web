# frozen_string_literal: true

class RepositoryDateRangeValue < RepositoryDateTimeRangeValueBase
  PRELOAD_INCLUDE = :repository_date_range_value

  def data_changed?(new_data)
    data = JSON.parse(new_data).symbolize_keys
    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.to_date != start_time.to_date || et.to_date != end_time.to_date
  end

  def formatted
    super(:full_date)
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
