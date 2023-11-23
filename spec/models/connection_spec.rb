# frozen_string_literal: true

require 'rails_helper'

describe Connection, type: :model do
  before do
    allow_any_instance_of(Connection).to receive(:ensure_non_cyclical)
  end

  let(:connection) { build :connection }

  it 'is valid' do
    expect(connection).to be_valid
  end

  it 'should be of class Connection' do
    expect(subject.class).to eq Connection
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :input_id }
    it { should have_db_column :output_id }
  end

  describe 'Relations' do
    it { should belong_to(:to).class_name('MyModule').with_foreign_key('input_id').inverse_of(:inputs) }
    it { should belong_to(:from).class_name('MyModule').with_foreign_key('output_id').inverse_of(:outputs) }
  end
end
