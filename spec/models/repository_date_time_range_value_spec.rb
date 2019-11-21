# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeRangeValue, type: :model do
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
end
