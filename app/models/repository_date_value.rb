# frozen_string_literal: true

class RepositoryDateValue < RepositoryDateTimeValueBase
  def data_changed?(new_data)
    new_time = Time.zone.parse(new_data)
    new_time.to_date != data.to_date
  end

  def formatted
    super(:full_date)
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'today'
      repository_rows.where("#{join_alias}.data >= ?", Time.zone.now.beginning_of_day)
    when 'yesterday'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day)
    when 'last_week'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week)
    when 'this_month'
      repository_rows.where("#{join_alias}.data >= ?", Time.zone.now.beginning_of_month)
    when 'last_year'
      repository_rows.where("#{join_alias}.data >= ? AND #{join_alias}.data < ?",
                            Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year)
    when 'this_year'
      repository_rows.where("#{join_alias}.data >= ?", Time.zone.now.beginning_of_year)
    when 'equal_to'
      repository_rows.where("#{join_alias}.data = ?", parameters['date'])
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.data = ?", parameters['date'])
    when 'greater_than'
      repository_rows.where("#{join_alias}.data > ?", parameters['date'])
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.data >= ?", parameters['date'])
    when 'less_than'
      repository_rows.where("#{join_alias}.data < ?", parameters['date'])
    when 'less_than_or_equal_to'
      repository_rows.where("#{join_alias}.data <= ?", parameters['date'])
    when 'between'
      repository_rows.where("#{join_alias}.data > ? AND #{join_alias}.data < ?",
                            parameters['start_date'], parameters['end_date'])
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateValue!'
    end
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Time.zone.parse(payload)
    value
  end

  def self.import_from_text(text, attributes, options = {})
    date_format = (options.dig(:user, :settings, :date_format) || Constants::DEFAULT_DATE_FORMAT).gsub(/%-/, '%')
    new(attributes.merge(data: DateTime.strptime(text, date_format)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
