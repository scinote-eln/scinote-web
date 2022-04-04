# frozen_string_literal: true

class RepositoryDateValue < RepositoryDateTimeValueBase
  include RepositoryValueWithReminders

  self.skip_time_zone_conversion_for_attributes = [:data]

  before_save -> { self.data = data.to_date }, if: :data_changed?

  def data_different?(new_data)
    Date.parse(new_data).to_date != data.to_date
  end

  def formatted
    super(:full_date)
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    parameters = filter_element.parameters
    case filter_element.operator
    when 'today'
      repository_rows.where("#{join_alias}.data::date = ?", Time.zone.now.to_date)
    when 'yesterday'
      repository_rows.where("#{join_alias}.data::date = ?", Time.zone.now.to_date - 1.day)
    when 'last_week'
      repository_rows.where("#{join_alias}.data::date >= ? AND #{join_alias}.data::date < ?",
                            Time.zone.now.beginning_of_week.to_date - 1.week, Time.zone.now.beginning_of_week.to_date)
    when 'this_month'
      repository_rows.where("#{join_alias}.data::date >= ? AND #{join_alias}.data::date <= ?",
                            Time.zone.now.beginning_of_month.to_date, Time.zone.now.end_of_month.to_date)
    when 'last_year'
      repository_rows.where("#{join_alias}.data::date >= ? AND #{join_alias}.data::date < ?",
                            Time.zone.now.beginning_of_year.to_date - 1.year, Time.zone.now.beginning_of_year.to_date)
    when 'this_year'
      repository_rows.where("#{join_alias}.data::date >= ? AND #{join_alias}.data::date <= ?",
                            Time.zone.now.beginning_of_year.to_date, Time.zone.now.end_of_year.to_date)
    when 'equal_to'
      repository_rows.where("#{join_alias}.data::date = ?", Date.parse(parameters['date']))
    when 'unequal_to'
      repository_rows.where.not("#{join_alias}.data::date = ?", Date.parse(parameters['date']))
    when 'greater_than_or_equal_to'
      repository_rows.where("#{join_alias}.data::date >= ?", Date.parse(parameters['date']))
    when 'less_than'
      repository_rows.where("#{join_alias}.data::date < ?", Date.parse(parameters['date']))
    when 'between'
      repository_rows.where("#{join_alias}.data::date > ? AND #{join_alias}.data::date < ?",
                            Date.parse(parameters['start_date']), Date.parse(parameters['end_date']))
    else
      raise ArgumentError, 'Wrong operator for RepositoryDateValue!'
    end
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = Date.parse(payload)
    value
  end

  def update_data!(new_data, user)
    self.data = Date.parse(new_data)
    self.last_modified_by = user
    save!
  end

  def self.import_from_text(text, attributes, options = {})
    date_format = (options.dig(:user, :settings, :date_format) || Constants::DEFAULT_DATE_FORMAT).gsub(/%-/, '%')
    new(attributes.merge(data: DateTime.strptime(text, date_format)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
