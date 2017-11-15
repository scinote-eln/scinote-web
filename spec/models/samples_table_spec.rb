require 'rails_helper'

describe SamplesTable, type: :model do
  it 'should be of class SamplesTable' do
    expect(subject.class).to eq SamplesTable
  end

  describe 'Database table' do
    it { should have_db_column :status }
    it { should have_db_column :user_id }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :team }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :team }
    it { should validate_presence_of :user }
  end
end
