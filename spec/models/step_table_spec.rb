# frozen_string_literal: true

require 'rails_helper'

describe StepTable, type: :model do
  let(:step_table) { build :step_table }

  it 'is valid' do
    expect(step_table).to be_valid
  end

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
end
