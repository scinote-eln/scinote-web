# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTimeRangeValue, type: :model do
  let(:time_range_value) do
    create :repository_time_range_value, start_time: Time.utc(2000, 10, 10), end_time: Time.utc(2000, 10, 11, 4, 11)
  end

  describe '.formatted' do
    it 'prints date format with time' do
      str = '00:00 - 04:11'
      expect(time_range_value.formatted).to eq(str)
    end
  end

  describe '.data_different?' do
    context 'when has different time value' do
      let(:new_values) do
        {
          start_time: Time.utc(2000, 10, 10, 12, 13).to_s,
          end_time: Time.utc(2000, 10, 12, 4, 11).to_s
        }.to_json
      end

      it do
        expect(time_range_value.data_different?(new_values)).to be_truthy
      end
    end

    context 'when has same time value (but different date)' do
      let(:new_values) do
        {
          start_time: Time.utc(2000, 10, 10).to_s,
          end_time: Time.utc(2012, 10, 14, 4, 11).to_s
        }.to_json
      end

      it do
        expect(time_range_value.data_different?(new_values)).to be_falsey
      end
    end
  end

  describe 'self.new_with_payload' do
    let(:user) { create :user }
    let(:column) { create :repository_column }
    let(:cell) { build :repository_cell, repository_column: column }
    let(:attributes) do
      {
        repository_cell: cell,
        created_by: user,
        last_modified_by: user
      }
    end
    let(:payload) do
      {
        start_time: Time.now.utc.to_s,
        end_time: (Time.now.utc + 1.day).to_s
      }.to_json
    end

    it do
      expect(RepositoryTimeRangeValue.new_with_payload(payload, attributes))
        .to be_an_instance_of RepositoryTimeRangeValue
    end
  end
end
