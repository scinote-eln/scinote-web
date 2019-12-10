# frozen_string_literal: true

class RepositoryDateTimeRangeValue < RepositoryDateTimeRangeValueBase
  def data_changed?(new_data)
    st = Time.zone.parse(new_data[:start_time])
    et = Time.zone.parse(new_data[:end_time])
    st.to_i != start_time.to_i || et.to_i != end_time.to_i
  end

  def formatted
    super(:full_with_comma)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.start_time = Time.zone.parse(payload[:start_time])
    value.end_time = Time.zone.parse(payload[:end_time])
    value
  end
end
