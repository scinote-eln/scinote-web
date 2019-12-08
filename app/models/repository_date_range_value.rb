# frozen_string_literal: true

class RepositoryDateRangeValue < RepositoryDateTimeRangeValueBase
  def data_changed?(new_data)
    st = Time.zone.parse(new_data[:start_time])
    et = Time.zone.parse(new_data[:end_time])
    formatted != formatted(new_dates: [st, et])
  end

  def formatted(new_dates: nil)
    super(:full_date, new_dates: new_dates)
  end
end
