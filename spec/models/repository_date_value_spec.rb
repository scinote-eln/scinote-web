# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateValue, type: :model do
  let(:date_value) do
    create :repository_date_value, data: Time.utc(2000, 10, 11)
  end

  describe '.formatted' do
    it 'prints date format with date' do
      str = '10/11/2000'
      expect(date_value.formatted).to eq(str)
    end
  end

  describe '.data_changed?' do
    context 'when has different date value' do
      let(:new_values) { Time.utc(2000, 12, 11, 4, 14).to_s }

      it do
        expect(date_value.data_changed?(new_values)).to be_truthy
      end
    end

    context 'when has same date value (but different time)' do
      let(:new_values) { Time.utc(2000, 10, 11, 4, 11).to_s }

      it do
        expect(date_value.data_changed?(new_values)).to be_falsey
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
      expect(RepositoryDateValue.new_with_payload(Time.now.utc.to_s, attributes))
        .to be_an_instance_of RepositoryDateValue
    end
  end
end
