# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateTimeValueBase, type: :model do
  let(:repository_date_time_value) { build :repository_date_time_value }

  it 'is valid' do
    expect(repository_date_time_value).to be_valid
  end

  describe 'Validations' do
    describe '#repository_cell' do
      it { is_expected.to validate_presence_of(:repository_cell) }
    end

    describe '#data' do
      it { is_expected.to validate_presence_of(:data) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
    it { is_expected.to have_one(:repository_cell) }
  end

  describe '.update_data!' do
    let(:user) { create :user }
    let(:new_data) { Time.now.utc.to_s }

    context 'when update data' do
      it 'should change last_modified_by and dates' do
        repository_date_time_value.save

        expect { repository_date_time_value.update_data!(new_data, user) }
          .to(change { repository_date_time_value.reload.last_modified_by.id }
                .and(change { repository_date_time_value.reload.data }))
      end
    end
  end

  describe 'self.import_from_text' do
    let(:user) { create :user }
    let(:date_string1) { '2020-01-22' }
    let(:date_string2) { '01-22-2020' }
    let(:date_string3) { '01/22/2020' }
    let(:test_date) { Date.parse('2020-01-22') }
    let(:attributes) { {} }

    it 'takes date format from user settings 1' do
      user.settings[:date_format] = '%Y-%m-%d'
      user.save
      result = RepositoryDateTimeValueBase
               .import_from_text(date_string1,
                                 attributes,
                                 user.as_json(root: true, only: :settings).deep_symbolize_keys)
      expect(result).to respond_to(:data)
      expect(result.data).to eq(test_date)
    end

    it 'takes date format from user settings 2' do
      user.settings[:date_format] = '%m-%d-%Y'
      user.save
      result = RepositoryDateTimeValueBase
               .import_from_text(date_string2,
                                 attributes,
                                 user.as_json(root: true, only: :settings).deep_symbolize_keys)
      expect(result).to respond_to(:data)
      expect(result.data).to eq(test_date)
    end

    it 'takes default date format when there is no user settings' do
      user.settings[:date_format] = nil
      user.save
      result = RepositoryDateTimeValueBase
               .import_from_text(date_string3,
                                 attributes,
                                 user.as_json(root: true, only: :settings).deep_symbolize_keys)
      expect(result).to respond_to(:data)
      expect(result.data).to eq(test_date)
    end
  end
end
