require 'rails_helper'

describe AssetTextDatum, type: :model do
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :data }
    it { should validate_presence_of :asset }
    it { should validate_uniqueness_of :asset }
  end
end
