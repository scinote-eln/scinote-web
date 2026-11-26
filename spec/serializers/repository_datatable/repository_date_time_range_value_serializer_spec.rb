# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatable::RepositoryDateTimeRangeValueSerializer do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:value_object) do
    build :repository_date_time_range_value,
          start_time: Time.zone.parse('2030-03-14 09:30'),
          end_time: Time.zone.parse('2030-03-16 17:45')
  end

  def value_for(object = value_object)
    described_class.new(object, scope: { repository: repository, options: {} }).value
  end

  it 'formats the start and end times with the same keys as the date time value' do
    expect(value_for).to eq(
      start_time: {
        formatted: "#{I18n.l(value_object.start_time, format: :full_date)}, 09:30",
        date_formatted: I18n.l(value_object.start_time, format: :full_date),
        time_formatted: '09:30',
        datetime: '2030/03/14 09:30'
      },
      end_time: {
        formatted: "#{I18n.l(value_object.end_time, format: :full_date)}, 17:45",
        date_formatted: I18n.l(value_object.end_time, format: :full_date),
        time_formatted: '17:45',
        datetime: '2030/03/16 17:45'
      }
    )
  end

  it 'reads the start and end from the value object, not from the scope' do
    other = build :repository_date_time_range_value,
                  start_time: Time.zone.parse('2031-01-02 08:00'),
                  end_time: Time.zone.parse('2031-01-03 08:00')

    value = value_for(other)

    expect(value[:start_time][:datetime]).to eq '2031/01/02 08:00'
    expect(value[:end_time][:datetime]).to eq '2031/01/03 08:00'
  end
end
