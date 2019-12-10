# frozen_string_literal: true

class RepositoryTimeRangeValue < RepositoryDateTimeRangeValueBase
  def data_changed?(new_data)
    st = Time.zone.parse(new_data[:start_time])
    et = Time.zone.parse(new_data[:end_time])
    st.hour != start_time.hour || et.hour != end_time.hour || st.min != start_time.min || et.min != end_time.min
  end

  def formatted
    super(:time)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.start_time = Time.zone.parse(payload[:start_time])
    value.end_time = Time.zone.parse(payload[:end_time])
    value
  end
end
