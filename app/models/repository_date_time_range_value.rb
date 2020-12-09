# frozen_string_literal: true

class RepositoryDateTimeRangeValue < RepositoryDateTimeRangeValueBase
<<<<<<< HEAD
  def data_different?(new_data)
=======
  PRELOAD_INCLUDE = :repository_date_time_range_value

  def data_changed?(new_data)
>>>>>>> Pulled latest release
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data
    st = Time.zone.parse(data[:start_time])
    et = Time.zone.parse(data[:end_time])
    st.to_i != start_time.to_i || et.to_i != end_time.to_i
  end

  def formatted
    super(:full_with_comma)
  end

<<<<<<< HEAD
  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'equal_to'
      repository_rows.where("#{join_alias}.start_time = ? AND #{join_alias}.end_time = ?",
                            Time.zone.parse(parameters['start_datetime']), Time.zone.parse(parameters['end_datetime']))
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.start_time = ? AND #{join_alias}.end_time = ?",
                                Time.zone.parse(parameters['start_datetime']),
                                Time.zone.parse(parameters['end_datetime']))
    when 'greater_than'
      repository_rows.where("#{join_alias}.start_time > ?", Time.zone.parse(parameters['end_datetime']))
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.start_time >= ?", Time.zone.parse(parameters['end_datetime']))
    when 'less_than'
      repository_rows.where("#{join_alias}.end_time < ?", Time.zone.parse(parameters['start_datetime']))
    when 'less_than_or_equal_to'
      repository_rows.where("#{join_alias}.end_time <= ?", Time.zone.parse(parameters['start_datetime']))
    when 'between'
      repository_rows.where("#{join_alias}.start_time > ? AND #{join_alias}.end_time < ?",
                            Time.zone.parse(parameters['start_datetime']), Time.zone.parse(parameters['end_datetime']))
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateTimeRangeValue!'
    end
  end

=======
>>>>>>> Pulled latest release
  def self.new_with_payload(payload, attributes)
    data = payload.is_a?(String) ? JSON.parse(payload).symbolize_keys : payload

    value = new(attributes)
    value.start_time = Time.zone.parse(data[:start_time])
    value.end_time = Time.zone.parse(data[:end_time])
    value
  end

  alias export_formatted formatted
end
