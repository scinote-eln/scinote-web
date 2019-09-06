# frozen_string_literal: true

require 'rails_helper'

describe ResultAsset, type: :model do
  let(:result_asset) { build :result_asset }

  it 'is valid' do
    expect(result_asset).to be_valid
  end

  it 'should be of class ResultAsset' do
    expect(subject.class).to eq ResultAsset
  end

  describe 'Database table' do
    it { should have_db_column :result_id }
    it { should have_db_column :asset_id }
  end

  describe 'Relations' do
    it { should belong_to :result }
    it { should belong_to :asset }
  end

  describe 'Validations' do
    it { should validate_presence_of :result }
    it { should validate_presence_of :asset }
  end
end
