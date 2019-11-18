# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeValue, type: :model do
  let(:repository_date_time_value) { create :repository_date_time_value, :datetime }

  it 'is valid' do
    expect(repository_date_time_value).to be_valid
  end

  it 'should be of class RepositoryDateTimeValue' do
    expect(subject.class).to eq RepositoryDateTimeValue
  end

  describe 'Validations' do
    describe '#repository_cell' do
      it { is_expected.to validate_presence_of(:repository_cell) }
    end

    describe '#datetime_type' do
      it { is_expected.to validate_presence_of(:datetime_type) }
    end

    describe '#start_time' do
      it { is_expected.to validate_presence_of(:start_time) }
    end

    describe '#end_time' do
      context 'when not range' do
        it { is_expected.to validate_absence_of(:end_time) }
      end
      context 'when range' do
        it do
          subject.datetime_type = :datetime_range
          is_expected.to validate_presence_of(:end_time)
        end
      end
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
    it { is_expected.to have_one(:repository_cell) }
  end
end
