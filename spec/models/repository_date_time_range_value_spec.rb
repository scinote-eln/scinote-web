# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeRangeValue, type: :model do
  let(:date_time_range_value) do
    create :repository_date_time_range_value, start_time: Time.utc(2000, 10, 10), end_time: Time.utc(2000, 10, 11)
  end

  describe '.formatted' do
    it 'prints date format with time' do
      str = '10/10/2000, 00:00 - 10/11/2000, 00:00'
      expect(date_time_range_value.formatted).to eq(str)
    end
  end

  describe '.data_changed?' do
    context 'when has different datetime value' do
      let(:new_values) do
        {
          start_time: Time.utc(2000, 10, 10).to_s,
          end_time: Time.utc(2000, 10, 12).to_s
        }
      end

      it do
        expect(date_time_range_value.data_changed?(new_values)).to be_truthy
      end
    end

    context 'when has same datetime value' do
      let(:new_values) do
        {
          start_time: Time.utc(2000, 10, 10).to_s,
          end_time: Time.utc(2000, 10, 11).to_s
        }
      end

      it do
        expect(date_time_range_value.data_changed?(new_values)).to be_falsey
      end
    end
  end
end
