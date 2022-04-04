# frozen_string_literal: true

class RepositoryDateTimeValue < RepositoryDateTimeValueBase
  include RepositoryValueWithReminders

  def data_different?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.to_i != data.to_i
  end

  def formatted
    super(:full_with_comma)
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'today'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data <= ?",
                            Time.zone.now.beginning_of_day, Time.zone.now.end_of_day)
    when 'yesterday'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day)
    when 'last_week'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week)
    when 'this_month'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data <= ?",
                            Time.zone.now.beginning_of_month, Time.zone.now.end_of_month)
    when 'last_year'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year)
    when 'this_year'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data <= ?",
                            Time.zone.now.beginning_of_year, Time.zone.now.end_of_year)
    when 'equal_to'
      repository_rows.where("#{join_alias}.data = ?", Time.zone.parse(parameters['datetime']))
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.data = ?", Time.zone.parse(parameters['datetime']))
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.data >= ?", Time.zone.parse(parameters['datetime']))
    when 'less_than'
      repository_rows.where("#{join_alias}.data < ?", Time.zone.parse(parameters['datetime']))
    when 'between'
      repository_rows.where("#{join_alias}.data > ? AND #{join_alias}.data < ?",
                            Time.zone.parse(parameters['start_datetime']), Time.zone.parse(parameters['end_datetime']))
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateTimeValue!'
    end
  end

  def export_formatted
    I18n.l(data, format: :full)
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  def self.import_from_text(text, attributes, options = {})
    date_format = (options.dig(:user, :settings, :date_format) || Constants::DEFAULT_DATE_FORMAT).gsub(/%-/, '%') + ' %H:%M'
    Time.zone = options.dig(:user, :settings, :time_zone) || 'UTC'
    new(attributes.merge(data: Time.zone.strptime(text, date_format)))
  rescue ArgumentError
    nil
  end
end
