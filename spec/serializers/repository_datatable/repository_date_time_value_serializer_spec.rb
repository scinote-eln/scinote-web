# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatable::RepositoryDateTimeValueSerializer do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:date_time) { Time.zone.parse('2030-03-14 09:30') }
  let(:value_object) { build :repository_date_time_value, data: date_time }
  let(:column) do
    build :repository_column, :date_time_type, repository: repository,
                                               reminder_value: 1, reminder_unit: 60 * 60 * 24 * 7,
                                               reminder_message: 'Check the sample'
  end
  let(:scope) { { repository: repository, column: column, options: { reminders_enabled: true } } }

  def value_for(scope_hash = scope)
    described_class.new(value_object, scope: scope_hash).value
  end

  it 'formats the date, the time and the full datetime separately' do
    value = value_for(scope.merge(options: {}))

    expect(value).to eq(
      formatted: "#{I18n.l(date_time, format: :full_date)}, 09:30",
      date_formatted: I18n.l(date_time, format: :full_date),
      time_formatted: '09:30',
      datetime: '2030/03/14 09:30'
    )
  end

  it 'keeps the date part of the formatted value equal to the date_formatted value' do
    value = value_for(scope.merge(options: {}))

    expect(value[:formatted]).to eq "#{value[:date_formatted]}, #{value[:time_formatted]}"
  end

  it 'adds no reminder data when reminders are disabled' do
    expect(value_for(scope.merge(options: {})).keys).to eq %i(formatted date_formatted time_formatted datetime)
  end

  it 'adds no reminder data for an inventory snapshot' do
    expect(value_for(scope.merge(repository: RepositorySnapshot.new)).keys)
      .to eq %i(formatted date_formatted time_formatted datetime)
  end

  it 'adds no reminder data when the column has no reminder value' do
    column.reminder_value = nil

    expect(value_for.keys).to eq %i(formatted date_formatted time_formatted datetime)
  end

  it 'shows a reminder that is not yet due without days left' do
    travel_to Time.zone.parse('2030-01-01 12:00') do
      expect(value_for).to include(reminder: false, reminder_message: 'Check the sample')
      expect(value_for).not_to have_key(:reminder_text)
    end
  end

  it 'shows the days left in weeks when the reminder falls due within the next weeks' do
    travel_to Time.zone.parse('2030-03-12 09:30') do
      expect(value_for).to include(reminder: true, days_left: 2,
                                   reminder_text: 'This item is expiring in 2 days.')
    end
  end

  it 'marks a reminder whose datetime has passed as expired' do
    travel_to Time.zone.parse('2030-03-20 12:00') do
      value = value_for

      expect(value).to include(reminder: true, reminder_text: 'This item has expired.')
      expect(value).not_to have_key(:days_left)
    end
  end
end
