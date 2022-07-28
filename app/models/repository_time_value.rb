# frozen_string_literal: true

class RepositoryTimeValue < RepositoryDateTimeValueBase
  SORTABLE_COLUMN_NAME = 'repository_date_time_values.data::time'

  def data_different?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.min != data.min || new_time.hour != data.hour
  end

  def formatted
    super(:time)
  end

  def self.saving_time_correction(origin_time, filter_time)
    origin_time += 1.hour if origin_time.dst? && !filter_time.dst?
    origin_time -= 1.hour if filter_time.dst? && !origin_time.dst?
    origin_time
  end

  def self.time_convert_helper(time_value, parameters, compare_operator)
    time_field = compare_operator == 'between' ? 'start_time' : 'time'
    time_value = saving_time_correction(time_value, Time.zone.parse(parameters[time_field]))
    filter_time = Time.zone.parse(parameters[time_field])
    filter_time_end = Time.zone.parse(parameters['end_time']) if compare_operator == 'between'
    return time_value.utc.strftime('%H%M%S'),
           filter_time.utc.strftime('%H%M%S'),
           filter_time_end&.utc&.strftime('%H%M%S')
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    compare_operator = filter_element.operator
    unfiltered_data = repository_rows.pluck('repository_rows.id',
                                            "#{join_alias}.data").map { |id, data| { id: id, data: data } }
    filtered_data = unfiltered_data.select do |row|
      if row[:data]
        time_value, filter_time, filter_time_end = time_convert_helper(Time.zone.parse(row[:data].to_s),
                                                                       parameters,
                                                                       compare_operator)
        case compare_operator
        when 'equal_to'
          time_value == filter_time
        when 'unequal_to'
          time_value != filter_time
        when 'greater_than'
          time_value > filter_time
        when 'greater_than_or_equal_to'
          time_value >= filter_time
        when 'less_than'
          time_value < filter_time
        when 'less_than_or_equal_to'
          time_value <= filter_time
        when 'between'
          filter_time < time_value && time_value < filter_time_end
        else
          raise ArgumentError, 'Wrong operator for RepositoryTimeValue!'
        end
      else
        false
      end
    end
    repository_rows.where(id: filtered_data.pluck(:id))
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
