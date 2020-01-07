# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeRangeValueBase, type: :model do
  let(:repository_date_time_range_value) { create :repository_date_time_range_value }

  it 'is valid' do
    expect(repository_date_time_range_value).to be_valid
  end

  describe 'Validations' do
    describe '#repository_cell' do
      it { is_expected.to validate_presence_of(:repository_cell) }
    end

    describe '#start_time' do
      it { is_expected.to validate_presence_of(:start_time) }
    end

    describe '#end_time' do
      it { is_expected.to validate_presence_of(:end_time) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
    it { is_expected.to have_one(:repository_cell) }
  end

  describe '.update_data!' do
    let(:user) { create :user }
    let(:new_times) do
      {
        start_time: Time.now.utc.to_s,
        end_time: (Time.zone.now + 2.days).utc.to_s
      }.to_json
    end

    context 'when update data' do
      it 'should change last_modified_by and dates' do
        repository_date_time_range_value.save

        expect { repository_date_time_range_value.update_data!(new_times, user) }
          .to(change { repository_date_time_range_value.reload.last_modified_by.id }
                .and(change { repository_date_time_range_value.reload.data }))
      end
    end
  end

  describe '.data' do
    it 'returns start and end time' do
      str = repository_date_time_range_value.start_time.to_s + ' - ' + repository_date_time_range_value.end_time.to_s
      expect(repository_date_time_range_value.data).to eq(str)
    end
  end
end
