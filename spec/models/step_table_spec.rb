require 'rails_helper'

describe StepTable, type: :model do
  it 'should be of class StepTable' do
    expect(subject.class).to eq StepTable
  end

  describe 'Database table' do
    it { should have_db_column :step_id }
    it { should have_db_column :table_id }
  end

  describe 'Relations' do
    it { should belong_to :step }
    it { should belong_to :table }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :step }
  end
end
