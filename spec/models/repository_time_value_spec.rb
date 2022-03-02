# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTimeValue, type: :model do
  let(:time_value) do
    create :repository_time_value, data: Time.utc(2000, 10, 11, 4, 11)
  end

  describe '.formatted' do
    it 'prints date format with time' do
      str = '04:11'
      expect(time_value.formatted).to eq(str)
    end
  end

  describe '.data_different?' do
    context 'when has different time value' do
      let(:new_values) { Time.utc(2000, 10, 11, 4, 14).to_s }

      it do
        expect(time_value.data_different?(new_values)).to be_truthy
      end
    end

    context 'when has same time value (but different date)' do
      let(:new_values) { Time.utc(1999, 10, 14, 4, 11).to_s }

      it do
        expect(time_value.data_different?(new_values)).to be_falsey
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

    it do
      expect(RepositoryTimeValue.new_with_payload(Time.now.utc.to_s, attributes))
        .to be_an_instance_of RepositoryTimeValue
    end
  end
end
