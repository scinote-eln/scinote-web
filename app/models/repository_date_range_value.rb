# frozen_string_literal: true

class RepositoryDateRangeValue < RepositoryDateTimeRangeValueBase
  def data_changed?(new_data)
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data
    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.to_date != start_time.to_date || et.to_date != end_time.to_date
  end

  def formatted
    super(:full_date)
  end

  def self.new_with_payload(payload, attributes)
    data = payload.is_a?(String) ? JSON.parse(payload).symbolize_keys : payload

    value = new(attributes)
    value.start_time = Time.zone.parse(data[:start_time])
    value.end_time = Time.zone.parse(data[:end_time])
    value
  end

  alias export_formatted formatted
end
