require 'rails_helper'

describe ResultTable, type: :model do
  it 'should be of class ResultTable' do
    expect(subject.class).to eq ResultTable
  end

  describe 'Database table' do
    it { should have_db_column :result_id }
    it { should have_db_column :table_id }
  end

  describe 'Relations' do
    it { should belong_to :result }
    it { should belong_to :table }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :result }
    it { should validate_presence_of :table }
  end
end
