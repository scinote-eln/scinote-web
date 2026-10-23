# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatable::RepositoryDateValueSerializer do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:date) { Time.zone.parse('2030-03-14 09:30') }
  let(:value_object) { build :repository_date_value, data: date }
  let(:column) do
    build :repository_column, :date_type, repository: repository,
                                          reminder_value: 2, reminder_unit: 60 * 60 * 24,
                                          reminder_message: 'Renew the reagent'
  end
  let(:scope) { { repository: repository, column: column, options: { reminders_enabled: true } } }

  def value_for(scope_hash = scope, object = value_object)
    described_class.new(object, scope: scope_hash).value
  end

  it 'formats the date without the time and keeps the full datetime' do
    expect(value_for(scope.merge(options: {}))).to eq(
      formatted: I18n.l(date, format: :full_date),
      datetime: '2030/03/14 09:30'
    )
  end

  it 'does not put the time into the formatted date' do
    expect(value_for(scope.merge(options: {}))[:formatted]).not_to include('09:30')
  end

  it 'returns the value and its type in the serializable hash' do
    serialized = described_class.new(value_object, scope: scope.merge(options: {})).serializable_hash

    expect(serialized).to eq(
      value: { formatted: I18n.l(date, format: :full_date), datetime: '2030/03/14 09:30' },
      value_type: 'RepositoryDateValue'
    )
  end

  it 'adds no reminder data when reminders are disabled for the table' do
    expect(value_for(scope.merge(options: {})).keys).to eq %i(formatted datetime)
  end

  it 'adds no reminder data for an inventory snapshot' do
    snapshot_scope = scope.merge(repository: RepositorySnapshot.new)

    expect(value_for(snapshot_scope).keys).to eq %i(formatted datetime)
  end

  it 'adds no reminder data when the column has no reminder unit' do
    column.reminder_unit = nil

    expect(value_for.keys).to eq %i(formatted datetime)
  end

  it 'flags a reminder that is not yet due without days left' do
    travel_to Time.zone.parse('2030-03-10 12:00') do
      expect(value_for).to eq(
        formatted: I18n.l(date, format: :full_date),
        datetime: '2030/03/14 09:30',
        reminder: false,
        reminder_message: 'Renew the reagent'
      )
    end
  end

  it 'shows the days left in the singular for a reminder due within one day' do
    travel_to Time.zone.parse('2030-03-13 12:00') do
      value = value_for

      expect(value).to include(reminder: true, days_left: 1, reminder_message: 'Renew the reagent',
                               reminder_text: 'This item is expiring in 1 day.')
    end
  end

  it 'shows the days left in the plural for a reminder due within several days' do
    travel_to Time.zone.parse('2030-03-12 09:30') do
      expect(value_for).to include(reminder: true, days_left: 2,
                                   reminder_text: 'This item is expiring in 2 days.')
    end
  end

  it 'marks a reminder whose date has passed as expired without days left' do
    travel_to Time.zone.parse('2030-03-15 12:00') do
      value = value_for

      expect(value).to include(reminder: true, reminder_text: 'This item has expired.')
      expect(value).not_to have_key(:days_left)
    end
  end
end
