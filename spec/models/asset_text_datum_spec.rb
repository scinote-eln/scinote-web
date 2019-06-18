# frozen_string_literal: true

require 'rails_helper'

describe AssetTextDatum, type: :model do
  let(:asset_text_datum) { build :asset_text_datum }

  it 'is valid' do
    expect(asset_text_datum).to be_valid
  end

  it 'should be of class Activity' do
    expect(subject.class).to eq AssetTextDatum
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :data }
    it { should have_db_column :asset_id }
    it { should have_db_column :created_at }
    it { should have_db_column :data_vector }
  end

  describe 'Relations' do
    it { should belong_to :asset }
  end

  describe 'Validations' do
    describe '#data' do
      it { is_expected.to validate_presence_of(:data) }
    end

    describe '#asset' do
      it { is_expected.to validate_presence_of(:asset) }
      it { expect(asset_text_datum).to validate_uniqueness_of(:asset) }
    end
  end
end
