# frozen_string_literal: true

require 'rails_helper'

describe ResultTable, type: :model do
  let(:result_table) { build :result_table }

  it 'is valid' do
    expect(result_table).to be_valid
  end

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
end
