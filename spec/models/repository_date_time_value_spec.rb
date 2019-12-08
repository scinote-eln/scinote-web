# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeValue, type: :model do
  let(:date_time_value) do
    create :repository_date_time_value, data: Time.utc(2000, 10, 11, 1, 4)
  end

  describe '.formatted' do
    it 'prints date format with date' do
      str = '10/11/2000, 01:04'
      expect(date_time_value.formatted).to eq(str)
    end
  end

  describe '.data_changed?' do
    context 'when has different datetime value' do
      let(:new_values) { Time.utc(2000, 12, 11, 4, 14).to_s }

      it do
        expect(date_time_value.data_changed?(new_values)).to be_truthy
      end
    end

    context 'when has same datetime value' do
      let(:new_values) { Time.utc(2000, 10, 11, 1, 4).to_s }

      it do
        expect(date_time_value.data_changed?(new_values)).to be_falsey
      end
    end
  end
end
