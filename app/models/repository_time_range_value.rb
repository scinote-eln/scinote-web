# frozen_string_literal: true

class RepositoryTimeRangeValue < RepositoryDateTimeRangeValueBase
  SORTABLE_COLUMN_NAME = 'repository_date_time_range_values.start_time::time'

  def data_different?(new_data)
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data

    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.hour != start_time.hour || et.hour != end_time.hour || st.min != start_time.min || et.min != end_time.min
  end

  def formatted
    super(:time)
  end

  def self.saving_time_correction(origin_time, filter_time)
    origin_time += 1.hour if origin_time.dst? && !filter_time.dst?
    origin_time -= 1.hour if filter_time.dst? && !origin_time.dst?
    origin_time
  end

  def self.time_convert_helper(time_value_start, time_value_end, parameters)
    return saving_time_correction(time_value_start, Time.zone.parse(parameters['start_time'])).utc.strftime('%H%M%S'),
           saving_time_correction(time_value_end, Time.zone.parse(parameters['end_time'])).utc.strftime('%H%M%S'),
           Time.zone.parse(parameters['start_time']).utc.strftime('%H%M%S'),
           Time.zone.parse(parameters['end_time']).utc.strftime('%H%M%S')
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    compare_operator = filter_element.operator
    unfiltered_data = repository_rows.pluck('repository_rows.id',
                                            "#{join_alias}.start_time",
                                            "#{join_alias}.end_time").map do |id, start_time, end_time|
      { id: id, start_time: start_time,
        end_time: end_time }
    end

    filtered_data = unfiltered_data.select do |row|
      if row[:start_time] && row[:end_time]
        time_value_start, time_value_end, filter_time_start, filter_time_end = time_convert_helper(
          Time.zone.parse(row[:start_time].to_s), Time.zone.parse(row[:end_time].to_s), parameters
        )
        case compare_operator
        when 'equal_to'
          time_value_start == filter_time_start && time_value_end == filter_time_end
        when 'unequal_to'
          time_value_start != filter_time_start || time_value_end != filter_time_end
        when 'greater_than'
          time_value_start > filter_time_end
        when 'greater_than_or_equal_to'
          time_value_start >= filter_time_end
        when 'less_than'
          time_value_end < filter_time_start
        when 'less_than_or_equal_to'
          time_value_end <= filter_time_start
        when 'between'
          time_value_start > filter_time_start && time_value_end < filter_time_end
        else
          raise ArgumentError, 'Wrong operator for RepositoryTimeRangeValue!'
        end
      else
        false
      end
    end
    repository_rows.where(id: filtered_data.pluck(:id))
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
