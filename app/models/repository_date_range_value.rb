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

  def self.add_filter_condition(repository_rows, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'equal_to'
      repository_rows.where("#{join_alias}.start_time::date = ? AND #{join_alias}.end_time::date = ?",
                            Time.zone.parse(parameters['start_date']), Time.zone.parse(parameters['end_date']))
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.start_time::date = ? AND #{join_alias}.end_time::date = ?",
                                Time.zone.parse(parameters['start_date']), Time.zone.parse(parameters['end_date']))
    when 'greater_than'
      repository_rows.where("#{join_alias}.start_time::date > ?", Time.zone.parse(parameters['end_date']))
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.start_time::date >= ?", Time.zone.parse(parameters['end_date']))
    when 'less_than'
      repository_rows.where("#{join_alias}.end_time::date < ?", Time.zone.parse(parameters['start_date']))
    when 'less_than_or_equal_to'
      repository_rows.where("#{join_alias}.end_time::date <= ?", Time.zone.parse(parameters['start_date']))
    when 'between'
      repository_rows.where("#{join_alias}.start_time::date > ? AND #{join_alias}.end_time::date < ?",
                            Time.zone.parse(parameters['start_date']), Time.zone.parse(parameters['end_date']))
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateRangeValue!'
    end
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
