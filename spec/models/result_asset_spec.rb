require 'rails_helper'

describe ResultAsset, type: :model do
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :result }
    it { should validate_presence_of :asset }
  end
end
