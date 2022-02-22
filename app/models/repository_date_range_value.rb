# frozen_string_literal: true

class RepositoryDateRangeValue < RepositoryDateTimeRangeValueBase
  self.skip_time_zone_conversion_for_attributes = %i(start_time end_time)

  before_save -> { self.start_time = start_time.to_date }, if: :start_time_changed?
  before_save -> { self.end_time = end_time.to_date }, if: :end_time_changed?

  def data_different?(new_data)
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data
    st = Date.parse(data[:start_time])
    et = Date.parse(data[:end_time])
    st.to_date != start_time.to_date || et.to_date != end_time.to_date
  end

  def formatted
    super(:full_date)
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'equal_to'
      repository_rows.where("#{join_alias}.start_time::date = ? AND #{join_alias}.end_time::date = ?",
                            Date.parse(parameters['start_date']), Date.parse(parameters['end_date']))
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.start_time::date = ? AND #{join_alias}.end_time::date = ?",
                                Date.parse(parameters['start_date']), Date.parse(parameters['end_date']))
    when 'greater_than'
      repository_rows.where("#{join_alias}.start_time::date > ?", Date.parse(parameters['end_date']))
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.start_time::date >= ?", Date.parse(parameters['end_date']))
    when 'less_than'
      repository_rows.where("#{join_alias}.end_time::date < ?", Date.parse(parameters['start_date']))
    when 'less_than_or_equal_to'
      repository_rows.where("#{join_alias}.end_time::date <= ?", Date.parse(parameters['start_date']))
    when 'between'
      repository_rows.where("#{join_alias}.start_time::date > ? AND #{join_alias}.end_time::date < ?",
                            Date.parse(parameters['start_date']), Date.parse(parameters['end_date']))
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateRangeValue!'
    end
  end

  def self.new_with_payload(payload, attributes)
    data = payload.is_a?(String) ? JSON.parse(payload).symbolize_keys : payload

    value = new(attributes)
    value.start_time = Date.parse(data[:start_time])
    value.end_time = Date.parse(data[:end_time])
    value
  end

  def update_data!(new_data, user)
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data
    self.start_time = Date.parse(data[:start_time])
    self.end_time = Date.parse(data[:end_time])
    self.last_modified_by = user
    save!
  end

  alias export_formatted formatted
end
